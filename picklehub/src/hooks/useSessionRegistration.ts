import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/contexts/AuthContext";
import { toast } from "sonner";

export interface SessionRegistration {
  id: string;
  session_id: number;
  user_id: string;
  registered_at: string;
  status: 'registered' | 'waitlist' | 'cancelled' | 'no_show';
  fee_amount?: number;
}

export interface SessionRegistrationWithUser extends SessionRegistration {
  user_profiles?: {
    first_name: string;
    last_name: string;
    skill_level: number;
    avatar_url?: string;
  };
  email?: string;
}

// Hook to get current user's registration status for a session
export const useUserSessionRegistration = (sessionId: string | number) => {
  const { user } = useAuth();
  
  return useQuery({
    queryKey: ["user-session-registration", sessionId, user?.id],
    queryFn: async () => {
      if (!user?.id) return null;
      
      const { data, error } = await supabase
        .from("session_registrations")
        .select("*")
        .eq('session_id', sessionId)
        .eq('user_id', user.id)
        .single();
      
      if (error && error.code !== 'PGRST116') { // PGRST116 is "not found"
        console.error("Error fetching user session registration:", error);
        throw error;
      }
      
      return data as SessionRegistration | null;
    },
    enabled: !!sessionId && !!user?.id,
  });
};

// Hook to get all registrations for a session with user details
export const useSessionRegistrations = (sessionId: string | number) => {
  const { user } = useAuth();
  
  return useQuery({
    queryKey: ["session-registrations", sessionId],
    queryFn: async () => {
      // Now that foreign key exists, try using join first
      const { data, error } = await supabase
        .from("session_registrations")
        .select(`
          *,
          user_profiles (
            first_name,
            last_name,
            skill_level,
            avatar_url
          )
        `)
        .eq('session_id', sessionId)
        .in('status', ['registered', 'waitlist'])
        .order('registered_at', { ascending: true });
      
      if (error) {
        console.error("Error fetching session registrations with join:", error);
        throw error;
      }
      
      // Add email info - show current user's email if they're in the list
      const registrationsWithUsers = data?.map(registration => ({
        ...registration,
        email: registration.user_id === user?.id ? user?.email : 'Email not available'
      })) || [];
      
      return registrationsWithUsers as SessionRegistrationWithUser[];
    },
    enabled: !!sessionId,
  });
};

// Hook to register for a session
export const useRegisterForSession = () => {
  const queryClient = useQueryClient();
  const { user } = useAuth();
  
  return useMutation({
    mutationFn: async ({ 
      sessionId, 
      session 
    }: { 
      sessionId: string | number;
      session: {
        max_participants?: number;
        fee_per_player?: number;
      };
    }) => {
      if (!user?.id) {
        throw new Error('User not authenticated');
      }


      // Check current registration count
      const { count, error: countError } = await supabase
        .from("session_registrations")
        .select("*", { count: 'exact', head: true })
        .eq('session_id', sessionId)
        .eq('status', 'registered');

      if (countError) {
        throw countError;
      }

      const registeredCount = count || 0;
      const maxParticipants = session.max_participants || 16;
      const isWaitlist = registeredCount >= maxParticipants;

      // Insert registration
      const { data, error } = await supabase
        .from("session_registrations")
        .insert({
          session_id: sessionId,
          user_id: user.id,
          status: isWaitlist ? 'waitlist' : 'registered',
          fee_amount: session.fee_per_player || 0
        })
        .select()
        .single();

      if (error) {
        console.error('Registration failed:', error.message);
        
        if (error.code === '23505') { // Unique constraint violation
          throw new Error('You are already registered for this session');
        }
        if (error.code === '42501') { // RLS policy violation
          throw new Error('Permission denied: Unable to register for this session');
        }
        throw error;
      }

      return { registration: data, isWaitlist };
    },
    onSuccess: ({ isWaitlist }, { sessionId }) => {
      // Invalidate related queries
      queryClient.invalidateQueries({ queryKey: ["session-registrations", sessionId] });
      queryClient.invalidateQueries({ queryKey: ["user-session-registration", sessionId] });
      queryClient.invalidateQueries({ queryKey: ["sessions-participant-counts"] });
      
      toast.success(isWaitlist ? "Added to waitlist!" : "Successfully registered!");
    },
    onError: (error) => {
      console.error('Registration error:', error);
      toast.error(error instanceof Error ? error.message : "Failed to register for session");
    },
  });
};

// Hook to unregister from a session
export const useUnregisterFromSession = () => {
  const queryClient = useQueryClient();
  const { user } = useAuth();
  
  return useMutation({
    mutationFn: async ({ sessionId }: { sessionId: string | number }) => {
      if (!user?.id) {
        throw new Error('User not authenticated');
      }

      // First, get the user's current registration
      const { data: currentRegistration, error: fetchError } = await supabase
        .from("session_registrations")
        .select("*")
        .eq('session_id', sessionId)
        .eq('user_id', user.id)
        .single();

      if (fetchError) {
        throw new Error('Registration not found');
      }

      // Delete the registration
      const { error: deleteError } = await supabase
        .from("session_registrations")
        .delete()
        .eq('session_id', sessionId)
        .eq('user_id', user.id);

      if (deleteError) {
        throw deleteError;
      }

      // If the user was registered (not waitlisted), promote the first waitlisted person
      if (currentRegistration.status === 'registered') {
        const { data: waitlistUsers, error: waitlistError } = await supabase
          .from("session_registrations")
          .select("*")
          .eq('session_id', sessionId)
          .eq('status', 'waitlist')
          .order('registered_at', { ascending: true })
          .limit(1);

        if (waitlistError) {
          console.error('Error fetching waitlist:', waitlistError);
          // Don't throw here, as the main deregistration succeeded
        } else if (waitlistUsers && waitlistUsers.length > 0) {
          // Promote the first person from waitlist
          const { error: promoteError } = await supabase
            .from("session_registrations")
            .update({ status: 'registered' })
            .eq('id', waitlistUsers[0].id);

          if (promoteError) {
            console.error('Error promoting from waitlist:', promoteError);
            // Don't throw here, as the main deregistration succeeded
          }
        }
      }

      return currentRegistration;
    },
    onSuccess: (_, { sessionId }) => {
      // Invalidate related queries
      queryClient.invalidateQueries({ queryKey: ["session-registrations", sessionId] });
      queryClient.invalidateQueries({ queryKey: ["user-session-registration", sessionId] });
      queryClient.invalidateQueries({ queryKey: ["sessions-participant-counts"] });
      
      toast.success("Successfully unregistered from session");
    },
    onError: (error) => {
      console.error('Unregistration error:', error);
      toast.error(error instanceof Error ? error.message : "Failed to unregister from session");
    },
  });
};
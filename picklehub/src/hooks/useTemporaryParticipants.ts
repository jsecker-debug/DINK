import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";

export interface TemporaryParticipant {
  id: string;
  session_id: number;
  name: string;
  skill_level: number;
  phone?: string;
  notes?: string;
  created_at: string;
  created_by: string;
}

// Hook to get temporary participants for a session
export const useTemporaryParticipants = (sessionId: string | number) => {
  return useQuery({
    queryKey: ["temporary-participants", sessionId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("temporary_session_participants")
        .select("*")
        .eq('session_id', sessionId)
        .order('created_at', { ascending: true });
      
      if (error) {
        console.error("Error fetching temporary participants:", error);
        throw error;
      }
      
      return data as TemporaryParticipant[];
    },
    enabled: !!sessionId,
  });
};

// Hook to add a temporary participant to a session
export const useAddTemporaryParticipant = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ 
      sessionId, 
      participant 
    }: { 
      sessionId: string | number;
      participant: {
        name: string;
        skill_level: number;
        phone?: string;
        notes?: string;
      };
    }) => {
      // Get current user
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        throw new Error('User not authenticated');
      }

      const { data, error } = await supabase
        .from("temporary_session_participants")
        .insert({
          session_id: sessionId,
          name: participant.name.trim(),
          skill_level: participant.skill_level,
          phone: participant.phone?.trim() || null,
          notes: participant.notes?.trim() || null,
          created_by: user.id
        })
        .select()
        .single();

      if (error) {
        console.error('Add temporary participant failed:', error.message);
        throw error;
      }

      return data;
    },
    onSuccess: (_, { sessionId }) => {
      queryClient.invalidateQueries({ queryKey: ["temporary-participants", sessionId] });
      toast.success("Temporary participant added successfully!");
    },
    onError: (error) => {
      console.error('Add temporary participant error:', error);
      toast.error(error instanceof Error ? error.message : "Failed to add temporary participant");
    },
  });
};

// Hook to remove a temporary participant from a session
export const useRemoveTemporaryParticipant = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ 
      participantId, 
      sessionId 
    }: { 
      participantId: string;
      sessionId: string | number;
    }) => {
      const { error } = await supabase
        .from("temporary_session_participants")
        .delete()
        .eq('id', participantId);

      if (error) {
        throw error;
      }

      return participantId;
    },
    onSuccess: (_, { sessionId }) => {
      queryClient.invalidateQueries({ queryKey: ["temporary-participants", sessionId] });
      toast.success("Temporary participant removed successfully!");
    },
    onError: (error) => {
      console.error('Remove temporary participant error:', error);
      toast.error(error instanceof Error ? error.message : "Failed to remove temporary participant");
    },
  });
};

// Hook to update a temporary participant
export const useUpdateTemporaryParticipant = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ 
      participantId, 
      sessionId,
      updates 
    }: { 
      participantId: string;
      sessionId: string | number;
      updates: {
        name?: string;
        skill_level?: number;
        phone?: string;
        notes?: string;
      };
    }) => {
      const cleanUpdates = {
        ...updates,
        name: updates.name?.trim(),
        phone: updates.phone?.trim() || null,
        notes: updates.notes?.trim() || null,
      };

      const { data, error } = await supabase
        .from("temporary_session_participants")
        .update(cleanUpdates)
        .eq('id', participantId)
        .select()
        .single();

      if (error) {
        throw error;
      }

      return data;
    },
    onSuccess: (_, { sessionId }) => {
      queryClient.invalidateQueries({ queryKey: ["temporary-participants", sessionId] });
      toast.success("Temporary participant updated successfully!");
    },
    onError: (error) => {
      console.error('Update temporary participant error:', error);
      toast.error(error instanceof Error ? error.message : "Failed to update temporary participant");
    },
  });
};
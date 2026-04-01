import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase";
import { useClub } from "@/contexts/ClubContext";
import { useAuth } from "@/contexts/AuthContext";

export interface ClubActivity {
  id: string;
  type: string;
  actor_id: string | null;
  target_id: string | null;
  target_type: string | null;
  data: any;
  created_at: string;
  // Joined data
  actor_profile?: {
    first_name: string;
    last_name: string;
    avatar_url: string | null;
  };
  target_session?: {
    Date: string;
    Venue: string;
    Status: string;
  };
  target_member?: {
    first_name: string;
    last_name: string;
    skill_level: number;
  };
}

export const useClubActivity = () => {
  const { selectedClubId } = useClub();
  const { user } = useAuth();
  
  return useQuery({
    queryKey: ["club-activity", selectedClubId],
    queryFn: async () => {
      if (!selectedClubId) {
        return [];
      }
      
      // Get activities for the current club with related data
      const { data, error } = await supabase
        .from("activities")
        .select(`
          *
        `)
        .eq("club_id", selectedClubId)
        .order("created_at", { ascending: false })
        .limit(20);
        
      if (error) {
        console.error("Error fetching club activities:", error);
        throw error;
      }
      
      // Fetch additional data for each activity
      const activitiesWithRelatedData = await Promise.all(
        (data || []).map(async (activity) => {
          let actorProfile = null;
          let targetSession = null;
          let targetMember = null;

          // Get actor profile
          if (activity.actor_id) {
            const { data: actorData } = await supabase
              .from('user_profiles')
              .select('first_name, last_name, avatar_url')
              .eq('id', activity.actor_id)
              .single();
            actorProfile = actorData;
          }

          // Get target data based on type
          if (activity.target_type === 'session' && activity.target_id) {
            const { data: sessionData } = await supabase
              .from('sessions')
              .select('Date, Venue, Status')
              .eq('id', parseInt(activity.target_id))
              .single();
            targetSession = sessionData;
          } else if (activity.target_type === 'participant' && activity.target_id) {
            const { data: memberData } = await supabase
              .from('user_profiles')
              .select('first_name, last_name, skill_level')
              .eq('id', activity.target_id)
              .single();
            targetMember = memberData;
          }

          return {
            ...activity,
            actor_profile: actorProfile,
            target_session: targetSession,
            target_member: targetMember
          };
        })
      );
      
      return activitiesWithRelatedData as ClubActivity[];
    },
    enabled: !!selectedClubId && !!user,
    staleTime: 5 * 60 * 1000, // 5 minutes
    refetchInterval: 30 * 1000, // Refetch every 30 seconds for live updates
  });
};

// Hook to get recent sessions for the feed
export const useRecentSessions = () => {
  const { selectedClubId } = useClub();
  const { user } = useAuth();
  
  return useQuery({
    queryKey: ["recent-sessions", selectedClubId],
    queryFn: async () => {
      if (!selectedClubId) {
        return [];
      }
      
      const { data, error } = await supabase
        .from("sessions")
        .select(`
          *
        `)
        .eq("club_id", selectedClubId)
        .order("created_at", { ascending: false })
        .limit(10);
        
      if (error) {
        console.error("Error fetching recent sessions:", error);
        throw error;
      }
      
      return data || [];
    },
    enabled: !!selectedClubId && !!user,
    staleTime: 5 * 60 * 1000,
  });
};

// Hook to get recent member joins
export const useRecentMembers = () => {
  const { selectedClubId } = useClub();
  const { user } = useAuth();
  
  return useQuery({
    queryKey: ["recent-members", selectedClubId],
    queryFn: async () => {
      if (!selectedClubId) {
        return [];
      }
      
      const { data, error } = await supabase
        .from("club_memberships")
        .select(`
          *
        `)
        .eq("club_id", selectedClubId)  
        .eq("status", "active")
        .order("joined_at", { ascending: false })
        .limit(10);

      if (error) {
        console.error("Error fetching recent members:", error);
        throw error;
      }

      // Fetch user profiles separately
      const membersWithProfiles = await Promise.all(
        (data || []).map(async (membership) => {
          if (membership.user_id) {
            const { data: profileData } = await supabase
              .from('user_profiles')
              .select('first_name, last_name, skill_level, avatar_url, created_at')
              .eq('id', membership.user_id)
              .single();
            
            return {
              ...membership,
              user_profiles: profileData
            };
          }
          return membership;
        })
      );

      return membersWithProfiles || [];
    },
    enabled: !!selectedClubId && !!user,
    staleTime: 5 * 60 * 1000,
  });
};

import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase";
import { useClub } from "@/contexts/ClubContext";
import type { Participant } from "@/types/scheduler";

export const useParticipants = () => {
  const { selectedClubId } = useClub();
  
  return useQuery({
    queryKey: ["participants", selectedClubId],
    queryFn: async () => {
      if (!selectedClubId) {
        return [];
      }
      
      // First get club memberships
      const { data: memberships, error: membershipError } = await supabase
        .from("club_memberships")
        .select("user_id")
        .eq("club_id", selectedClubId)
        .eq("status", "active");
        
      if (membershipError) {
        throw membershipError;
      }
      
      if (!memberships || memberships.length === 0) {
        return [];
      }
      
      // Get user IDs
      const userIds = memberships.map(m => m.user_id);
      
      // Then get user profiles for those users
      const { data: profiles, error: profileError } = await supabase
        .from("user_profiles")
        .select(`
          id,
          first_name,
          last_name,
          phone,
          skill_level,
          gender,
          total_games_played,
          wins,
          losses,
          rating_confidence,
          rating_volatility,
          avatar_url,
          preferences,
          created_at,
          updated_at
        `)
        .in("id", userIds);
        
      if (profileError) {
        throw profileError;
      }
      
      // Transform the data to match the Participant type
      const participants = (profiles || []).map((profile: any) => {
        const fullName = `${profile.first_name || ''} ${profile.last_name || ''}`.trim();
        
        return {
          id: profile.id,
          name: fullName || 'Unknown User',
          phone: profile.phone,
          skill_level: profile.skill_level,
          gender: profile.gender,
          total_games_played: profile.total_games_played || 0,
          wins: profile.wins || 0,
          losses: profile.losses || 0,
          rating_confidence: profile.rating_confidence || 0,
          rating_volatility: profile.rating_volatility || 1.0,
          level: profile.skill_level || 0,
          avatar_url: profile.avatar_url,
          preferences: profile.preferences,
          created_at: profile.created_at,
          updated_at: profile.updated_at,
          club_id: selectedClubId, // Add club_id for compatibility
        };
      });
      
      return participants.sort((a, b) => a.name.localeCompare(b.name)) as Participant[];
    },
    enabled: !!selectedClubId,
  });
};


import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase";
import { useClub } from "@/contexts/ClubContext";

export interface Session {
  id: string | number;
  created_at: string;
  Date: string;
  Venue: string;
  Status: 'Upcoming' | 'Completed' | 'Cancelled';
  club_id?: string;
  fee_per_player?: number;
  max_participants?: number;
  registration_deadline?: string;
}

export const useSessions = () => {
  const { selectedClubId } = useClub();
  
  return useQuery({
    queryKey: ["sessions", selectedClubId],
    queryFn: async () => {
      if (!selectedClubId) {
        return [];
      }
      
      const { data, error } = await supabase
        .from("sessions")
        .select("*")
        .eq('club_id', selectedClubId)
        .order('Date', { ascending: true });
      
      if (error) {
        console.error("Error fetching sessions:", error);
        throw error;
      }
      
      return data as Session[];
    },
    enabled: !!selectedClubId, // Only run query when a club is selected
  });
};

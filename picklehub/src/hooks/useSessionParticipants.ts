import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase";

// Hook to get participant counts for multiple sessions (used by Schedule page)
export const useSessionsParticipantCounts = (sessionIds: (string | number)[]) => {
  return useQuery({
    queryKey: ["sessions-participant-counts", sessionIds],
    queryFn: async () => {
      if (sessionIds.length === 0) return {};
      
      const { data, error } = await supabase
        .from("session_registrations")
        .select("session_id")
        .in('session_id', sessionIds)
        .eq('status', 'registered');
      
      if (error) {
        console.error("Error fetching sessions participant counts:", error);
        throw error;
      }
      
      // Count registrations per session
      const counts: Record<string | number, number> = {};
      sessionIds.forEach(id => counts[id] = 0);
      
      data?.forEach(registration => {
        counts[registration.session_id] = (counts[registration.session_id] || 0) + 1;
      });
      
      return counts;
    },
    enabled: sessionIds.length > 0,
  });
};
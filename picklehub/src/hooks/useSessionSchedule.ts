
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";
import type { Rotation } from "@/types/scheduler";

export const useSessionSchedule = (sessionId: string | null) => {
  return useQuery({
    queryKey: ["session-schedule", sessionId],
    queryFn: async () => {
      if (!sessionId) return null;

      // Fetch all rotations for the session
      const { data: rotationData, error: rotationError } = await supabase
        .from('rotations')
        .select(`
          id,
          is_king_court,
          rotation_number,
          court_assignments (
            court_number,
            team1_players,
            team2_players
          ),
          rotation_resters (
            resting_players
          )
        `)
        .eq('session_id', sessionId)
        .order('rotation_number', { ascending: true });

      if (rotationError) throw rotationError;

      // Transform the data to match our Rotation type
      const transformedRotations: Rotation[] = rotationData.map(rotation => ({
        courts: rotation.court_assignments.map(court => ({
          team1: court.team1_players,
          team2: court.team2_players
        })),
        resters: rotation.rotation_resters[0]?.resting_players || []
      }));

      // Separate random rotations and king court rotation
      const randomRotations = transformedRotations.filter((_, idx) => 
        rotationData[idx].is_king_court === false
      );

      const kingCourtRotation = transformedRotations.find((_, idx) => 
        rotationData[idx].is_king_court === true
      ) || null;

      return {
        rotations: transformedRotations,
        randomRotations,
        kingCourtRotation
      };
    },
    enabled: !!sessionId
  });
};

// Hook to delete session schedule
export const useDeleteSessionSchedule = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (sessionId: string) => {
      try {
        // First get all rotation IDs for this session
        const { data: rotations, error: rotationFetchError } = await supabase
          .from('rotations')
          .select('id')
          .eq('session_id', sessionId);

        if (rotationFetchError) {
          console.error("Error fetching rotations:", rotationFetchError);
          throw rotationFetchError;
        }

        if (!rotations || rotations.length === 0) {
          // No rotations to delete
          return sessionId;
        }

        const rotationIds = rotations.map(r => r.id);

        // Delete court assignments first
        const { error: courtError } = await supabase
          .from('court_assignments')
          .delete()
          .in('rotation_id', rotationIds);

        if (courtError) {
          console.error("Error deleting court assignments:", courtError);
          throw new Error(`Failed to delete court assignments: ${courtError.message}`);
        }

        // Delete rotation resters
        const { error: restersError } = await supabase
          .from('rotation_resters')
          .delete()
          .in('rotation_id', rotationIds);

        if (restersError) {
          console.error("Error deleting rotation resters:", restersError);
          throw new Error(`Failed to delete rotation resters: ${restersError.message}`);
        }

        // Finally delete rotations
        const { error: rotationError } = await supabase
          .from('rotations')
          .delete()
          .eq('session_id', sessionId);

        if (rotationError) {
          console.error("Error deleting rotations:", rotationError);
          throw new Error(`Failed to delete rotations: ${rotationError.message}`);
        }

        return sessionId;
      } catch (error) {
        console.error("Delete schedule error:", error);
        throw error;
      }
    },
    onSuccess: (sessionId) => {
      queryClient.invalidateQueries({ queryKey: ["session-schedule", sessionId] });
      toast.success("Schedule deleted successfully!");
    },
    onError: (error) => {
      console.error("Error deleting schedule:", error);
      const errorMessage = error instanceof Error ? error.message : "Failed to delete schedule";
      toast.error(errorMessage);
    }
  });
};

import { useState } from "react";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import type { Rotation } from "@/types/scheduler";

export const useGameSchedule = (selectedSession: string) => {
  const [rotations, setRotations] = useState<Rotation[]>([]);
  const [kingCourtRotation, setKingCourtRotation] = useState<Rotation | null>(null);
  const queryClient = useQueryClient();

  const saveScheduleMutation = useMutation({
    mutationFn: async () => {
      if (!selectedSession) {
        throw new Error("Please select a session");
      }

      console.log('Starting schedule save for session:', selectedSession);

      // Save random schedule rotations
      for (let i = 0; i < rotations.length; i++) {
        const rotation = rotations[i];
        
        // Insert rotation
        const { data: rotationData, error: rotationError } = await supabase
          .from('rotations')
          .insert({
            session_id: selectedSession,
            is_king_court: false,
            rotation_number: i + 1
          })
          .select()
          .single();

        if (rotationError) throw rotationError;

        // Insert court assignments
        const courtAssignments = rotation.courts.map((court, courtIndex) => ({
          rotation_id: rotationData.id,
          court_number: courtIndex + 1,
          team1_players: court.team1,
          team2_players: court.team2
        }));

        const { error: courtsError } = await supabase
          .from('court_assignments')
          .insert(courtAssignments);

        if (courtsError) throw courtsError;

        // Insert resters if any
        if (rotation.resters.length > 0) {
          const { error: restersError } = await supabase
            .from('rotation_resters')
            .insert({
              rotation_id: rotationData.id,
              resting_players: rotation.resters
            });

          if (restersError) throw restersError;
        }
      }

      // Save king of court rotation if exists
      if (kingCourtRotation) {
        const { data: kingRotationData, error: kingRotationError } = await supabase
          .from('rotations')
          .insert({
            session_id: selectedSession,
            is_king_court: true,
            rotation_number: null
          })
          .select()
          .single();

        if (kingRotationError) throw kingRotationError;

        // Insert court assignments for king of court
        const kingCourtAssignments = kingCourtRotation.courts.map((court, courtIndex) => ({
          rotation_id: kingRotationData.id,
          court_number: courtIndex + 1,
          team1_players: court.team1,
          team2_players: court.team2
        }));

        const { error: kingCourtsError } = await supabase
          .from('court_assignments')
          .insert(kingCourtAssignments);

        if (kingCourtsError) throw kingCourtsError;

        // Insert resters if any
        if (kingCourtRotation.resters.length > 0) {
          const { error: kingRestersError } = await supabase
            .from('rotation_resters')
            .insert({
              rotation_id: kingRotationData.id,
              resting_players: kingCourtRotation.resters
            });

          if (kingRestersError) throw kingRestersError;
        }
      }

      // Update session status to Ready
      const { error: sessionUpdateError } = await supabase
        .from('sessions')
        .update({ Status: 'Ready' })
        .eq('id', selectedSession);

      if (sessionUpdateError) throw sessionUpdateError;

      console.log('Schedule saved successfully and session marked as Ready');
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["sessions"] });
      toast.success("Schedule saved to session successfully");
    },
    onError: (error) => {
      console.error("Error saving schedule:", error);
      toast.error("Failed to save schedule to session");
    },
  });

  return {
    rotations,
    setRotations,
    kingCourtRotation,
    setKingCourtRotation,
    saveScheduleMutation
  };
};
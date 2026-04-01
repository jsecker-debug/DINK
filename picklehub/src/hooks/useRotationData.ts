
import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import { Rotation } from "@/types/scheduler";

export const useRotationData = (rotations: Rotation[], sessionId?: string) => {
  const [localRotations, setLocalRotations] = useState<Rotation[]>(rotations);

  useEffect(() => {
    const fetchRotationIds = async () => {
      if (!sessionId) return;
      
      const { data, error } = await supabase
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
      
      if (error) throw error;

      const updatedRotations = rotations.map((rotation, index) => ({
        ...rotation,
        id: data.find(r => r.rotation_number === index + 1)?.id
      }));
      
      setLocalRotations(updatedRotations);
    };

    fetchRotationIds();
  }, [sessionId, rotations]);

  return { localRotations, setLocalRotations };
};

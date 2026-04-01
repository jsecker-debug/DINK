import { supabase } from "@/lib/supabase";
import { toast } from "sonner";
import { Rotation } from "@/types/scheduler";

export const updateRotationInDatabase = async (
  targetRotation: Rotation,
  sessionId: string
) => {
  try {
    // Update all courts in the rotation
    const updatePromises = targetRotation.courts.map((court, i) => 
      supabase
        .from('court_assignments')
        .update({
          team1_players: court.team1,
          team2_players: court.team2
        })
        .eq('rotation_id', targetRotation.id)
        .eq('court_number', i + 1)
    );

    // Update resters
    updatePromises.push(
      supabase
        .from('rotation_resters')
        .update({
          resting_players: targetRotation.resters
        })
        .eq('rotation_id', targetRotation.id)
    );

    // Update rotation flag
    updatePromises.push(
      supabase
        .from('rotations')
        .update({ manually_modified: true })
        .eq('id', targetRotation.id)
    );

    // Wait for all updates to complete
    const results = await Promise.all(updatePromises);
    
    // Check if any updates failed
    const hasError = results.some(result => result.error);
    if (hasError) {
      throw new Error('One or more updates failed');
    }

    return true;
  } catch (error) {
    console.error('Error updating player positions:', error);
    return false;
  }
};

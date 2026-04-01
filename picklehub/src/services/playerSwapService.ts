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
        .from('roation_resters')
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

export const handlePlayerSwap = (
  selectedPlayer: string,
  targetTeamType: 'team1' | 'team2',
  targetCourtIndex: number,
  targetRotation: Rotation,
  specifiedTargetPlayer?: string
): Rotation | null => {
  // Create a deep copy of the rotation to avoid state mutations
  const updatedRotation = JSON.parse(JSON.stringify(targetRotation));
  
  // Find the selected player's current position
  let sourceCourtIndex = -1;
  let sourceTeamType: 'team1' | 'team2' | null = null;
  let isSelectedPlayerResting = false;

  // Check if selected player is resting
  if (updatedRotation.resters.includes(selectedPlayer)) {
    isSelectedPlayerResting = true;
  } else {
    // Find player in courts
    for (let i = 0; i < updatedRotation.courts.length; i++) {
      const court = updatedRotation.courts[i];
      if (court.team1.includes(selectedPlayer)) {
        sourceCourtIndex = i;
        sourceTeamType = 'team1';
        break;
      }
      if (court.team2.includes(selectedPlayer)) {
        sourceCourtIndex = i;
        sourceTeamType = 'team2';
        break;
      }
    }
  }

  // If we can't find the selected player's position and they're not resting, return error
  if (!sourceTeamType && !isSelectedPlayerResting) {
    toast.error("Could not find selected player's position");
    return null;
  }

  // Get target player and validate swap
  let targetPlayer = specifiedTargetPlayer;
  let isTargetPlayerResting = targetCourtIndex === -1;

  if (!targetPlayer) {
    toast.error("No target player specified for swap");
    return null;
  }

  if (isTargetPlayerResting) {
    // Validate target player is actually resting
    if (!updatedRotation.resters.includes(targetPlayer)) {
      toast.error("Specified target player is not in resting position");
      return null;
    }
  } else {
    const targetCourt = updatedRotation.courts[targetCourtIndex];
    if (!targetCourt) {
      toast.error("Invalid court selected");
      return null;
    }

    // Verify the target position is valid and contains the specified player
    if (!targetCourt[targetTeamType] || !targetCourt[targetTeamType].includes(targetPlayer)) {
      toast.error("Target player not found in specified position");
      return null;
    }

    // Prevent swapping to same team
    if (sourceCourtIndex === targetCourtIndex && sourceTeamType === targetTeamType) {
      toast.error("Cannot swap player with their own position");
      return null;
    }

    // Prevent same player appearing twice on a team
    const targetTeamPlayers = targetCourt[targetTeamType];
    if (targetTeamPlayers.includes(selectedPlayer)) {
      toast.error("Player cannot be on the same team twice");
      return null;
    }
  }

  // Additional validation to ensure we're not swapping a player with themselves
  if (targetPlayer === selectedPlayer) {
    toast.error("Cannot swap a player with themselves");
    return null;
  }

  // Perform the swap
  if (isSelectedPlayerResting) {
    // Remove selected player from resters
    updatedRotation.resters = updatedRotation.resters.filter(p => p !== selectedPlayer);
    
    if (isTargetPlayerResting) {
      // Both players are in resters
      updatedRotation.resters = updatedRotation.resters.filter(p => p !== targetPlayer);
      updatedRotation.resters.push(selectedPlayer);
    } else {
      // Move target player to resters and place selected player in their position
      const targetCourt = updatedRotation.courts[targetCourtIndex];
      const targetPlayerIndex = targetCourt[targetTeamType].indexOf(targetPlayer);
      if (targetPlayerIndex === -1) {
        toast.error("Target player not found in specified position");
        return null;
      }
      updatedRotation.resters.push(targetPlayer);
      targetCourt[targetTeamType][targetPlayerIndex] = selectedPlayer;
    }
  } else if (sourceTeamType) {
    const sourceCourt = updatedRotation.courts[sourceCourtIndex];
    
    if (isTargetPlayerResting) {
      // Move selected player to resters and target player to court
      const sourcePlayerIndex = sourceCourt[sourceTeamType].indexOf(selectedPlayer);
      if (sourcePlayerIndex === -1) {
        toast.error("Selected player not found in specified position");
        return null;
      }
      updatedRotation.resters = updatedRotation.resters.filter(p => p !== targetPlayer);
      sourceCourt[sourceTeamType][sourcePlayerIndex] = targetPlayer;
      updatedRotation.resters.push(selectedPlayer);
    } else {
      // Standard court-to-court swap
      const targetCourt = updatedRotation.courts[targetCourtIndex];
      const sourcePlayerIndex = sourceCourt[sourceTeamType].indexOf(selectedPlayer);
      const targetPlayerIndex = targetCourt[targetTeamType].indexOf(targetPlayer);
      
      if (sourcePlayerIndex === -1 || targetPlayerIndex === -1) {
        toast.error("One or both players not found in specified positions");
        return null;
      }
      
      // Perform the swap using exact indices
      sourceCourt[sourceTeamType][sourcePlayerIndex] = targetPlayer;
      targetCourt[targetTeamType][targetPlayerIndex] = selectedPlayer;
    }
  }

  return updatedRotation;
};

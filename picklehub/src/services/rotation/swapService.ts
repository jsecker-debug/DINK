
import { Rotation } from "@/types/scheduler";
import { PlayerPosition } from "./types";
import { toast } from "sonner";

export const performSwap = (
  selectedPlayer: string,
  targetPlayer: string,
  sourcePosition: PlayerPosition,
  targetPosition: PlayerPosition,
  rotation: Rotation
): Rotation => {
  const updatedRotation = JSON.parse(JSON.stringify(rotation));

  // Handle swaps involving resting players
  if (sourcePosition.isResting) {
    // Remove selected player from resters
    updatedRotation.resters = updatedRotation.resters.filter(p => p !== selectedPlayer);

    if (targetPosition.isResting) {
      // Both players are resting
      updatedRotation.resters = updatedRotation.resters.filter(p => p !== targetPlayer);
      updatedRotation.resters.push(selectedPlayer);
    } else {
      // Move target player to resters, put selected player in their spot
      const targetCourt = updatedRotation.courts[targetPosition.courtIndex!];
      const targetIndex = targetCourt[targetPosition.teamType!].indexOf(targetPlayer);
      updatedRotation.resters.push(targetPlayer);
      targetCourt[targetPosition.teamType!][targetIndex] = selectedPlayer;
    }
  } else {
    const sourceCourt = updatedRotation.courts[sourcePosition.courtIndex!];
    const sourceIndex = sourceCourt[sourcePosition.teamType!].indexOf(selectedPlayer);

    if (targetPosition.isResting) {
      // Move selected player to resters, put target player in their spot
      updatedRotation.resters = updatedRotation.resters.filter(p => p !== targetPlayer);
      sourceCourt[sourcePosition.teamType!][sourceIndex] = targetPlayer;
      updatedRotation.resters.push(selectedPlayer);
    } else {
      // Standard court-to-court swap
      const targetCourt = updatedRotation.courts[targetPosition.courtIndex!];
      const targetIndex = targetCourt[targetPosition.teamType!].indexOf(targetPlayer);
      
      sourceCourt[sourcePosition.teamType!][sourceIndex] = targetPlayer;
      targetCourt[targetPosition.teamType!][targetIndex] = selectedPlayer;
    }
  }

  return updatedRotation;
};

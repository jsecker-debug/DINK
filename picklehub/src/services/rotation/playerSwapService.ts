
import { toast } from "sonner";
import { Rotation } from "@/types/scheduler";
import { validateSwap, findPlayerPosition } from "./validationService";
import { performSwap } from "./swapService";
import { updateRotationInDatabase } from "./databaseService";

export { updateRotationInDatabase } from "./databaseService";

export const handlePlayerSwap = (
  selectedPlayer: string,
  targetTeamType: 'team1' | 'team2',
  targetCourtIndex: number,
  targetRotation: Rotation,
  specifiedTargetPlayer?: string
): Rotation | null => {
  if (!specifiedTargetPlayer) {
    toast.error("No target player specified for swap");
    return null;
  }

  // Find source position
  const sourcePosition = findPlayerPosition(selectedPlayer, targetRotation);
  if (!sourcePosition) {
    toast.error("Could not find selected player's position");
    return null;
  }

  // Find target position
  const targetPosition = findPlayerPosition(specifiedTargetPlayer, targetRotation);
  if (!targetPosition) {
    toast.error("Could not find target player's position");
    return null;
  }

  // Validate the swap
  if (!validateSwap(selectedPlayer, specifiedTargetPlayer, sourcePosition, targetPosition, targetRotation)) {
    return null;
  }

  // Perform the swap
  return performSwap(selectedPlayer, specifiedTargetPlayer, sourcePosition, targetPosition, targetRotation);
};

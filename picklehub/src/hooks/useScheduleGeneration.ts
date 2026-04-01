import { parsePlayers, shuffle } from "@/utils/gameUtils";
import type { Rotation } from "@/types/scheduler";
import { toast } from "sonner";
import type { Participant } from "@/types/scheduler";

interface UseScheduleGenerationProps {
  temporaryPlayers: string;
  selectedParticipants: string[];
  participants: Participant[] | undefined;
  setRotations: (rotations: Rotation[]) => void;
  setKingCourtRotation: (rotation: Rotation | null) => void;
  rotationCount: number;
}

export const useScheduleGeneration = ({
  temporaryPlayers,
  selectedParticipants,
  participants,
  setRotations,
  setKingCourtRotation,
  rotationCount
}: UseScheduleGenerationProps) => {
  const generateRandomSchedule = () => {
    const players = parsePlayers(temporaryPlayers, selectedParticipants, participants || []);
    if (players.length < 4) {
      toast.error("Please select at least 4 players");
      return;
    }

    const totalPlayers = players.length;
    const rotations: Rotation[] = [];
    const restCounts = new Array(totalPlayers).fill(0);
    const restHistory = new Array(totalPlayers).fill(0); // Track last rotation each player rested

    for (let rotationNum = 0; rotationNum < rotationCount; rotationNum++) {
      const maxPlayersPerRotation = Math.floor(totalPlayers / 4) * 4;
      const restersCount = totalPlayers - maxPlayersPerRotation;

      // Calculate rest priority for each player
      const playersWithPriority = players.map((_, idx) => ({
        idx,
        restCount: restCounts[idx],
        lastRested: restHistory[idx],
        priority: 0
      }));

      // Calculate priority based on rest count and last rested rotation
      playersWithPriority.forEach(player => {
        // Higher priority for players who haven't rested yet
        if (player.restCount === 0) {
          player.priority = 1000;
        } else {
          // For players who have rested, prioritize based on:
          // 1. Lower rest count
          // 2. Longer time since last rest
          player.priority = (1 / player.restCount) * 100 + (rotationNum - player.lastRested);
        }
      });

      // Sort by priority (highest first) and add some randomization for equal priorities
      playersWithPriority.sort((a, b) => {
        const priorityDiff = b.priority - a.priority;
        return priorityDiff !== 0 ? priorityDiff : Math.random() - 0.5;
      });

      // Select resters based on priority
      const resters = playersWithPriority.slice(0, restersCount).map(p => p.idx);

      // Update rest counts and history
      resters.forEach(idx => {
        restCounts[idx]++;
        restHistory[idx] = rotationNum;
      });

      // Get non-resting players
      const nonResters = players
        .map((_, idx) => idx)
        .filter(idx => !resters.includes(idx));
      shuffle(nonResters);

      // Create courts
      const courts = [];
      for (let i = 0; i < nonResters.length; i += 4) {
        if (i + 3 < nonResters.length) {
          const courtIndices = nonResters.slice(i, i + 4);
          const courtPlayers = courtIndices.map((idx) => players[idx]);
          courts.push({
            team1: [courtPlayers[0], courtPlayers[1]],
            team2: [courtPlayers[2], courtPlayers[3]]
          });
        }
      }

      rotations.push({
        courts: courts,
        resters: resters.map((idx) => players[idx])
      });
    }

    setRotations(rotations);
  };

  const generateKingCourt = () => {
    const players = parsePlayers(temporaryPlayers, selectedParticipants, participants || []);
    if (players.length < 4) {
      toast.error("Please select at least 4 players");
      return;
    }

    const totalPlayers = players.length;
    const maxPlayers = Math.floor(totalPlayers / 4) * 4;
    const restersCount = totalPlayers - maxPlayers;

    const sortedPlayers = players.map((_, idx) => idx);
    shuffle(sortedPlayers);

    const resters = sortedPlayers.slice(0, restersCount);
    const nonResters = sortedPlayers.slice(restersCount);
    shuffle(nonResters);

    const courts = [];
    for (let i = 0; i < nonResters.length; i += 4) {
      if (i + 3 < nonResters.length) {
        const courtIndices = nonResters.slice(i, i + 4);
        const courtPlayers = courtIndices.map((idx) => players[idx]);
        courts.push({
          team1: [courtPlayers[0], courtPlayers[1]],
          team2: [courtPlayers[2], courtPlayers[3]]
        });
      }
    }

    setKingCourtRotation({
      courts: courts,
      resters: resters.map((idx) => players[idx])
    });
  };

  const generateSchedule = () => {
    generateRandomSchedule();
    generateKingCourt();
  };

  return { generateSchedule };
};

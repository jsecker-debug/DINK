import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";
import type { Rotation } from "@/types/scheduler";
import type { SessionRegistrationWithUser } from "@/hooks/useSessionRegistration";
import { useTemporaryParticipants } from "@/hooks/useTemporaryParticipants";

interface SessionPlayer {
  id: string;
  name: string;
  skillLevel?: number;
}

interface SessionScheduleGenerationProps {
  sessionId: string;
  registeredUsers: SessionRegistrationWithUser[];
}

export const useSessionScheduleGeneration = ({ 
  sessionId, 
  registeredUsers 
}: SessionScheduleGenerationProps) => {
  const [rotations, setRotations] = useState<Rotation[]>([]);
  const [scheduleSettings, setScheduleSettings] = useState({
    courts: 4,
    rounds: 8
  });
  const queryClient = useQueryClient();
  const { data: temporaryParticipants = [] } = useTemporaryParticipants(sessionId);

  // Convert registered users and temporary participants to session players
  const getSessionPlayers = (): SessionPlayer[] => {
    // Get registered users
    const registeredPlayers = registeredUsers
      .filter(user => user.status === 'registered')
      .map(user => ({
        id: user.user_id,
        name: user.user_profiles?.first_name && user.user_profiles?.last_name 
          ? `${user.user_profiles.first_name} ${user.user_profiles.last_name}`
          : user.user_profiles?.first_name || 'Unknown Player',
        skillLevel: user.user_profiles?.skill_level
      }));

    // Get temporary participants
    const tempPlayers = temporaryParticipants.map(temp => ({
      id: `temp_${temp.id}`,
      name: temp.name,
      skillLevel: temp.skill_level
    }));

    // Combine both lists
    return [...registeredPlayers, ...tempPlayers];
  };

  const generateSessionSchedule = () => {
    const players = getSessionPlayers();
    
    if (players.length < 4) {
      toast.error("Need at least 4 registered players to generate a schedule");
      return;
    }

    const { courts, rounds } = scheduleSettings;
    const maxPlayersPerRound = courts * 4; // 4 players per court
    const totalPlayers = players.length;
    
    if (totalPlayers < maxPlayersPerRound) {
      toast.error(`Not enough players. Need at least ${maxPlayersPerRound} players for ${courts} courts`);
      return;
    }

    const generatedRotations: Rotation[] = [];
    const restCounts = new Array(totalPlayers).fill(0);
    const restHistory = new Array(totalPlayers).fill(-1); // Track last rotation each player rested
    
    // Track partnerships: partnershipCounts[i][j] = number of times player i partnered with player j
    const partnershipCounts = Array(totalPlayers).fill(null).map(() => Array(totalPlayers).fill(0));

    for (let roundNum = 0; roundNum < rounds; roundNum++) {
      const playersThisRound = Math.min(maxPlayersPerRound, totalPlayers);
      const restersCount = Math.max(0, totalPlayers - playersThisRound);

      let resterIndices: number[] = [];
      let playingIndices: number[] = [];

      if (restersCount === 0) {
        // No resters needed - all players play
        playingIndices = players.map((_, idx) => idx);
      } else {
        // Calculate rest priority for each player - LOWER priority means more likely to rest
        const playersWithPriority = players.map((_, idx) => ({
          idx,
          restCount: restCounts[idx],
          lastRested: restHistory[idx],
          priority: 0
        }));

        // Calculate priority: players who haven't rested get LOWEST priority (should rest first)
        playersWithPriority.forEach(player => {
          if (player.restCount === 0) {
            // Players who haven't rested should rest first - give them LOW priority
            player.priority = 0;
          } else {
            // Players who have rested get higher priority (less likely to rest again)
            // The more they've rested and the more recently they rested, the higher their priority
            const timeSinceRest = player.lastRested === -1 ? rounds : (roundNum - player.lastRested);
            player.priority = player.restCount * 1000 + (rounds - timeSinceRest) * 100;
          }
        });

        // Sort by priority (lowest first for resting selection)
        playersWithPriority.sort((a, b) => {
          const priorityDiff = a.priority - b.priority;
          if (priorityDiff !== 0) return priorityDiff;
          
          // If priorities are equal, prioritize by:
          // 1. Who rested least recently (longer time since last rest)
          // 2. Random if still tied
          const aTimeSinceRest = a.lastRested === -1 ? rounds : (roundNum - a.lastRested);
          const bTimeSinceRest = b.lastRested === -1 ? rounds : (roundNum - b.lastRested);
          const timeDiff = bTimeSinceRest - aTimeSinceRest;
          return timeDiff !== 0 ? timeDiff : Math.random() - 0.5;
        });

        // Select resters (lowest priority players - those who should rest)
        resterIndices = playersWithPriority
          .slice(0, restersCount)
          .map(p => p.idx);

        // Update rest counts and history for resters
        resterIndices.forEach(idx => {
          restCounts[idx]++;
          restHistory[idx] = roundNum;
        });

        // Get playing players (not resting) - those with higher priority
        playingIndices = playersWithPriority
          .slice(restersCount)
          .map(p => p.idx);
      }

      // Create optimal pairings to minimize repeated partnerships
      const roundCourts = createOptimalPairings(playingIndices, partnershipCounts, players);

      // Update partnership counts
      roundCourts.forEach(court => {
        // Find player indices for team members
        const team1Indices = court.team1.map(name => players.findIndex(p => p.name === name));
        const team2Indices = court.team2.map(name => players.findIndex(p => p.name === name));
        
        // Update partnership counts for team 1
        if (team1Indices[0] !== -1 && team1Indices[1] !== -1) {
          partnershipCounts[team1Indices[0]][team1Indices[1]]++;
          partnershipCounts[team1Indices[1]][team1Indices[0]]++;
        }
        
        // Update partnership counts for team 2
        if (team2Indices[0] !== -1 && team2Indices[1] !== -1) {
          partnershipCounts[team2Indices[0]][team2Indices[1]]++;
          partnershipCounts[team2Indices[1]][team2Indices[0]]++;
        }
      });

      // Add rotation
      generatedRotations.push({
        courts: roundCourts,
        resters: resterIndices.map(idx => players[idx].name)
      });
    }

    setRotations(generatedRotations);
    toast.success(`Generated ${rounds} rounds for ${totalPlayers} players on ${courts} courts`);
  };

  // Helper function to create optimal pairings that minimize repeated partnerships
  const createOptimalPairings = (playingIndices: number[], partnershipCounts: number[][], players: SessionPlayer[]) => {
    const courts = [];
    const availablePlayers = [...playingIndices];
    
    // Create courts (4 players per court)
    while (availablePlayers.length >= 4) {
      let bestPairing = null;
      let lowestScore = Infinity;
      
      // Try all possible combinations of 4 players from available players
      for (let i = 0; i < availablePlayers.length - 3; i++) {
        for (let j = i + 1; j < availablePlayers.length - 2; j++) {
          for (let k = j + 1; k < availablePlayers.length - 1; k++) {
            for (let l = k + 1; l < availablePlayers.length; l++) {
              const fourPlayers = [availablePlayers[i], availablePlayers[j], availablePlayers[k], availablePlayers[l]];
              
              // Try different team combinations for these 4 players
              const teamCombinations = [
                { team1: [fourPlayers[0], fourPlayers[1]], team2: [fourPlayers[2], fourPlayers[3]] },
                { team1: [fourPlayers[0], fourPlayers[2]], team2: [fourPlayers[1], fourPlayers[3]] },
                { team1: [fourPlayers[0], fourPlayers[3]], team2: [fourPlayers[1], fourPlayers[2]] }
              ];
              
              teamCombinations.forEach(combination => {
                const score = calculatePartnershipScore(combination, partnershipCounts);
                if (score < lowestScore) {
                  lowestScore = score;
                  bestPairing = {
                    players: fourPlayers,
                    teams: combination
                  };
                }
              });
            }
          }
        }
      }
      
      if (bestPairing) {
        // Remove selected players from available pool
        bestPairing.players.forEach(playerIdx => {
          const index = availablePlayers.indexOf(playerIdx);
          if (index > -1) availablePlayers.splice(index, 1);
        });
        
        // Add court with player names
        courts.push({
          team1: bestPairing.teams.team1.map(idx => players[idx].name),
          team2: bestPairing.teams.team2.map(idx => players[idx].name)
        });
      } else {
        // Fallback: just group remaining players
        if (availablePlayers.length >= 4) {
          const courtPlayers = availablePlayers.splice(0, 4);
          courts.push({
            team1: [players[courtPlayers[0]].name, players[courtPlayers[1]].name],
            team2: [players[courtPlayers[2]].name, players[courtPlayers[3]].name]
          });
        }
      }
    }
    
    return courts;
  };

  // Calculate partnership score (lower is better - fewer repeated partnerships)
  const calculatePartnershipScore = (teamCombination: { team1: number[], team2: number[] }, partnershipCounts: number[][]) => {
    let score = 0;
    
    // Score for team 1 partnership
    if (teamCombination.team1.length === 2) {
      score += partnershipCounts[teamCombination.team1[0]][teamCombination.team1[1]];
    }
    
    // Score for team 2 partnership
    if (teamCombination.team2.length === 2) {
      score += partnershipCounts[teamCombination.team2[0]][teamCombination.team2[1]];
    }
    
    return score;
  };

  const saveScheduleMutation = useMutation({
    mutationFn: async () => {
      if (rotations.length === 0) {
        throw new Error("No schedule to save");
      }

      // First, delete any existing schedule for this session
      // Get existing rotation IDs
      const { data: existingRotations } = await supabase
        .from('rotations')
        .select('id')
        .eq('session_id', sessionId);

      if (existingRotations && existingRotations.length > 0) {
        const rotationIds = existingRotations.map(r => r.id);

        // Delete court assignments first
        const { error: courtDeleteError } = await supabase
          .from('court_assignments')
          .delete()
          .in('rotation_id', rotationIds);

        if (courtDeleteError) throw courtDeleteError;

        // Delete rotation resters
        const { error: restDeleteError } = await supabase
          .from('rotation_resters')
          .delete()
          .in('rotation_id', rotationIds);

        if (restDeleteError) throw restDeleteError;

        // Now delete the rotations
        const { error: rotationDeleteError } = await supabase
          .from('rotations')
          .delete()
          .eq('session_id', sessionId);

        if (rotationDeleteError) throw rotationDeleteError;
      }

      // Save each rotation
      for (let i = 0; i < rotations.length; i++) {
        const rotation = rotations[i];
        
        // Insert rotation record
        const { data: rotationData, error: rotationError } = await supabase
          .from('rotations')
          .insert({
            session_id: sessionId,
            rotation_number: i + 1,
            is_king_court: false
          })
          .select()
          .single();

        if (rotationError) throw rotationError;

        // Insert court assignments
        for (let courtIdx = 0; courtIdx < rotation.courts.length; courtIdx++) {
          const court = rotation.courts[courtIdx];
          
          const { error: courtError } = await supabase
            .from('court_assignments')
            .insert({
              rotation_id: rotationData.id,
              court_number: courtIdx + 1,
              team1_players: court.team1,
              team2_players: court.team2
            });

          if (courtError) throw courtError;
        }

        // Insert resting players if any
        if (rotation.resters.length > 0) {
          const { error: restError } = await supabase
            .from('rotation_resters')
            .insert({
              rotation_id: rotationData.id,
              resting_players: rotation.resters
            });

          if (restError) throw restError;
        }
      }

      return rotations;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["session-schedule", sessionId] });
      toast.success("Schedule saved successfully!");
    },
    onError: (error) => {
      console.error("Error saving schedule:", error);
      toast.error("Failed to save schedule");
    }
  });

  return {
    rotations,
    setRotations,
    scheduleSettings,
    setScheduleSettings,
    generateSessionSchedule,
    saveScheduleMutation,
    totalPlayers: getSessionPlayers().length
  };
};
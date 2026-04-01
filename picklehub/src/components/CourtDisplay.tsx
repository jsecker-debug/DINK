import { useState } from "react";
import { Card } from "@/components/ui/card";
import { toast } from "sonner";
import { supabase } from "@/lib/supabase";
import CourtCard from "./court/CourtCard";
import RestingPlayers from "./court/RestingPlayers";
import { usePlayersData } from "@/hooks/usePlayersData";
import { useRotationData } from "@/hooks/useRotationData";
import { handlePlayerSwap, updateRotationInDatabase } from "@/services/rotation/playerSwapService";
import { Court } from "@/types/scheduler";
import { CourtDisplayProps, SwapData } from "@/types/court-display";

const CourtDisplay = ({ rotations, isKingCourt, sessionId, sessionStatus }: CourtDisplayProps) => {
  const [scores, setScores] = useState<{ [key: string]: { team1: string; team2: string } }>({});
  const players = usePlayersData();
  const { localRotations, setLocalRotations } = useRotationData(rotations, sessionId);

  const handleScoreChange = (
    rotationIndex: number,
    courtIndex: number,
    team: 'team1' | 'team2',
    value: string
  ) => {
    setScores(prev => ({
      ...prev,
      [`${rotationIndex}-${courtIndex}`]: {
        ...prev[`${rotationIndex}-${courtIndex}`],
        [team]: value
      }
    }));
  };

  const handleDragStart = async (e: React.DragEvent, data: SwapData) => {
    const newRotations = [...localRotations];
    const targetRotation = newRotations[data.rotationIndex];
    
    const updatedRotation = handlePlayerSwap(
      data.player,
      data.teamType,
      data.courtIndex,
      targetRotation,
      data.targetPlayer // Pass the specified target player
    );

    if (!updatedRotation) return;

    if (sessionId && targetRotation.id) {
      const success = await updateRotationInDatabase(updatedRotation, sessionId);
      if (!success) {
        toast.error("Failed to update player positions");
        return;
      }
      // Update the rotation in our local state after successful DB update
      newRotations[data.rotationIndex] = updatedRotation;
      setLocalRotations(newRotations);
      toast.success("Player position updated successfully");
    } else {
      // Update local state for non-persisted changes
      newRotations[data.rotationIndex] = updatedRotation;
      setLocalRotations(newRotations);
      toast.success("Player position updated");
    }
  };

  const handleSubmitScore = async (rotationIndex: number, courtIndex: number, court: Court) => {
    const key = `${rotationIndex}-${courtIndex}`;
    const scoreData = scores[key];

    if (!scoreData?.team1 || !scoreData?.team2) {
      toast.error("Please enter scores for both teams");
      return;
    }

    const team1Score = parseInt(scoreData.team1);
    const team2Score = parseInt(scoreData.team2);

    if (isNaN(team1Score) || isNaN(team2Score)) {
      toast.error("Please enter valid numbers for scores");
      return;
    }

    if (team1Score === team2Score) {
      toast.error("Scores cannot be equal");
      return;
    }

    const winningTeam = team1Score > team2Score ? court.team1 : court.team2;
    const losingTeam = team1Score > team2Score ? court.team2 : court.team1;
    const winningScore = Math.max(team1Score, team2Score);
    const losingScore = Math.min(team1Score, team2Score);

    try {
      const { error } = await supabase
        .from('game_results')
        .insert({
          session_id: sessionId,
          court_number: courtIndex + 1,
          winning_team_players: winningTeam,
          losing_team_players: losingTeam,
          winning_team_score: winningScore,
          losing_team_score: losingScore,
          game_number: rotationIndex + 1,
          is_best_of_three: isKingCourt
        });

      if (error) throw error;

      toast.success("Score submitted successfully");
      
      setScores(prev => {
        const newScores = { ...prev };
        delete newScores[key];
        return newScores;
      });

    } catch (error) {
      console.error('Error submitting score:', error);
      toast.error("Failed to submit score");
    }
  };

  return (
    <div className="space-y-8">
      <div id="court-rotations">
        {localRotations.map((rotation, idx) => (
          <Card key={idx} className="p-6 mb-8 bg-card border-2 border-border shadow-lg">
            <div className="mb-6 pb-3 border-b-2 border-primary/20">
              <h2 className="text-2xl font-bold text-primary flex items-center gap-3">
                <div className="w-8 h-8 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-sm font-bold">
                  {idx + 1}
                </div>
                {isKingCourt ? "King of the Court Initial Rotation" : `Rotation ${idx + 1}`}
              </h2>
            </div>
            
            <div className="grid gap-8 md:grid-cols-2 xl:grid-cols-3">
              {rotation.courts.map((court, courtIdx) => (
                <CourtCard
                  key={courtIdx}
                  court={court}
                  courtIndex={courtIdx}
                  rotationIndex={idx}
                  onDragStart={handleDragStart}
                  playerGenders={Object.fromEntries(
                    Object.entries(players).map(([name, data]) => [name, data.gender])
                  )}
                  showScores={sessionStatus === 'Ready' && !isKingCourt}
                  scores={scores[`${idx}-${courtIdx}`] || { team1: '', team2: '' }}
                  onScoreChange={(team, value) => handleScoreChange(idx, courtIdx, team, value)}
                  onSubmitScore={() => handleSubmitScore(idx, courtIdx, court)}
                  allCourts={rotation.courts}
                  restingPlayers={rotation.resters}
                />
              ))}
            </div>

            <RestingPlayers 
              resters={rotation.resters} 
              players={players}
              rotationIndex={idx}
              onDragStart={handleDragStart}
              allCourts={rotation.courts}
            />
          </Card>
        ))}
      </div>
    </div>
  );
};

export default CourtDisplay;

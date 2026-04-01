import { useState } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import CourtCard from "./court/CourtCard";
import RestingPlayers from "./court/RestingPlayers";
import GameScoreInput from "./court/GameScoreInput";
import { usePlayersData } from "@/hooks/usePlayersData";
import { useRotationData } from "@/hooks/useRotationData";
import { useSessionGameScores, useSaveGameScores, useTriggerRatingUpdates } from "@/hooks/useGameScores";
import { handlePlayerSwap, updateRotationInDatabase } from "@/services/rotation/playerSwapService";
import { CourtDisplayProps, SwapData } from "@/types/court-display";
import { useAuth } from "@/contexts/AuthContext";
import { Trophy, Calculator } from "lucide-react";

const CourtDisplayWithScoring = ({ rotations, isKingCourt, sessionId, sessionStatus }: CourtDisplayProps) => {
  const [showScoring, setShowScoring] = useState(false);
  const { user } = useAuth();
  const players = usePlayersData();
  const { localRotations, setLocalRotations } = useRotationData(rotations, sessionId);
  
  const { data: gameScores = [] } = useSessionGameScores(sessionId);
  const saveScoresMutation = useSaveGameScores();
  const triggerRatingUpdatesMutation = useTriggerRatingUpdates();


  const handleDragStart = async (e: React.DragEvent, data: SwapData) => {
    // If no target player is specified, this is just a drag start event
    if (!data.targetPlayer) return;
    
    // Perform the player swap
    try {
      const newRotations = [...localRotations];
      const targetRotation = newRotations[data.rotationIndex];
      
      const updatedRotation = handlePlayerSwap(
        data.player,
        'team1', // This parameter is not actually used in the function
        0,       // This parameter is not actually used in the function  
        targetRotation,
        data.targetPlayer
      );

      if (!updatedRotation) return;

      if (sessionId && targetRotation.id) {
        const success = await updateRotationInDatabase(updatedRotation, sessionId);
        if (!success) {
          toast.error("Failed to update player positions");
          return;
        }
        newRotations[data.rotationIndex] = updatedRotation;
        setLocalRotations(newRotations);
        toast.success("Player position updated successfully");
      } else {
        newRotations[data.rotationIndex] = updatedRotation;
        setLocalRotations(newRotations);
      }
    } catch (error) {
      console.error('Error updating rotation:', error);
      toast.error("Failed to move player");
    }
  };

  const handleSaveScores = async (
    courtNumber: number,
    rotationNumber: number,
    team1Players: string[],
    team2Players: string[],
    scores: Array<{ game_number: number; team1_score: number; team2_score: number }>
  ) => {
    try {
      await saveScoresMutation.mutateAsync({
        sessionId: parseInt(sessionId),
        courtNumber,
        rotationNumber,
        team1Players,
        team2Players,
        scores
      });
      toast.success("Scores saved successfully");
    } catch (error) {
      console.error('Error saving scores:', error);
      toast.error("Failed to save scores");
    }
  };

  const handleUpdateRatings = async () => {
    try {
      await triggerRatingUpdatesMutation.mutateAsync(parseInt(sessionId));
      toast.success("Ratings updated for all players with recorded games");
    } catch (error) {
      console.error('Error updating ratings:', error);
      toast.error("Failed to update ratings");
    }
  };

  const getCourtScores = (courtNumber: number, rotationNumber: number) => {
    return gameScores.filter(
      score => score.court_number === courtNumber && score.rotation_number === rotationNumber
    );
  };

  const hasAnyScores = gameScores.length > 0;
  const isScoreEditingDisabled = sessionStatus === 'Completed' && !user; // Only admins can edit after completion

  return (
    <div className="space-y-8">
      {/* Scoring Controls */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button
            variant={showScoring ? "default" : "outline"}
            onClick={() => setShowScoring(!showScoring)}
            className="flex items-center gap-2"
          >
            <Trophy className="h-4 w-4" />
            {showScoring ? "Hide Scoring" : "Show Scoring"}
          </Button>
          
          {hasAnyScores && (
            <Badge variant="secondary" className="flex items-center gap-1">
              <Trophy className="h-3 w-3" />
              {gameScores.length} games recorded
            </Badge>
          )}
        </div>

        {hasAnyScores && (
          <Button 
            onClick={handleUpdateRatings}
            disabled={triggerRatingUpdatesMutation.isPending}
            className="flex items-center gap-2"
          >
            <Calculator className="h-4 w-4" />
            {triggerRatingUpdatesMutation.isPending ? "Updating..." : "Update Ratings"}
          </Button>
        )}
      </div>

      {/* Court Rotations */}
      <div id="court-rotations">
        {localRotations.map((rotation, rotationIdx) => (
          <Card key={rotationIdx} className="p-6 mb-8 bg-card border-2 border-border shadow-lg">
            <div className="mb-6 pb-3 border-b-2 border-primary/20">
              <h2 className="text-2xl font-bold text-primary flex items-center gap-3">
                <div className="w-8 h-8 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-sm font-bold">
                  {rotationIdx + 1}
                </div>
                Rotation {rotationIdx + 1}
                {isKingCourt && (
                  <Badge variant="secondary" className="bg-yellow-500/10 text-yellow-700 border-yellow-500/20">
                    King Court
                  </Badge>
                )}
              </h2>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
              {/* Courts */}
              {rotation.courts?.map((court, courtIdx) => (
                <div key={courtIdx} className="space-y-4">
                  <CourtCard
                    court={court}
                    courtIndex={courtIdx}
                    rotationIndex={rotationIdx}
                    onDragStart={handleDragStart}
                    playerGenders={Object.fromEntries(
                      Object.entries(players || {}).map(([name, data]) => [name, data.gender || 'M'])
                    )}
                    showScores={false} // We handle scoring separately
                    scores={{ team1: '', team2: '' }}
                    onScoreChange={() => {}}
                    onSubmitScore={() => {}}
                    allCourts={rotation.courts || []}
                    restingPlayers={rotation.resters || []}
                  />
                  
                  {/* Game Scoring */}
                  {showScoring && (
                    <GameScoreInput
                      courtNumber={courtIdx + 1}
                      team1Players={court.team1}
                      team2Players={court.team2}
                      existingScores={getCourtScores(courtIdx + 1, rotationIdx + 1).map(score => ({
                        game_number: score.game_number,
                        team1_score: score.team1_score,
                        team2_score: score.team2_score
                      }))}
                      onSaveScores={(scores) => handleSaveScores(
                        courtIdx + 1,
                        rotationIdx + 1,
                        court.team1,
                        court.team2,
                        scores
                      )}
                      disabled={isScoreEditingDisabled}
                    />
                  )}
                </div>
              ))}

              {/* Resting Players */}
              {rotation.resters && rotation.resters.length > 0 && (
                <RestingPlayers
                  resters={rotation.resters}
                  players={players}
                  rotationIndex={rotationIdx}
                  onDragStart={handleDragStart}
                  allCourts={rotation.courts || []}
                />
              )}
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
};

export default CourtDisplayWithScoring;
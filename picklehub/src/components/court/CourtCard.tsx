
import { Card } from "@/components/ui/card";
import TeamDisplay from "./TeamDisplay";
import ScoreInput from "./ScoreInput";
import { Court } from "@/types/scheduler";

interface CourtCardProps {
  court: Court;
  courtIndex: number;
  rotationIndex: number;
  onDragStart: (e: React.DragEvent, data: { 
    player: string; 
    teamType: 'team1' | 'team2';
    courtIndex: number;
    rotationIndex: number;
  }) => void;
  playerGenders: { [key: string]: string };
  showScores: boolean;
  scores: { team1: string; team2: string };
  onScoreChange: (team: 'team1' | 'team2', value: string) => void;
  onSubmitScore: () => void;
  allCourts: Court[];
  restingPlayers: string[];
}

const CourtCard = ({
  court,
  courtIndex,
  rotationIndex,
  onDragStart,
  playerGenders,
  showScores,
  scores,
  onScoreChange,
  onSubmitScore,
  allCourts,
  restingPlayers,
}: CourtCardProps) => {
  return (
    <Card className="p-4 border-2 border-primary/20 bg-card shadow-md">
      <h3 className="text-lg font-semibold mb-3 text-primary bg-primary/10 px-3 py-1 rounded-md text-center">
        Court {courtIndex + 1}
      </h3>
      <div className="space-y-2">
        <TeamDisplay
          label="Team 1"
          players={court.team1}
          teamType="team1"
          courtIndex={courtIndex}
          rotationIndex={rotationIndex}
          onDragStart={onDragStart}
          allCourts={allCourts}
          playerGenders={playerGenders}
          restingPlayers={restingPlayers}
        />
        <TeamDisplay
          label="Team 2"
          players={court.team2}
          teamType="team2"
          courtIndex={courtIndex}
          rotationIndex={rotationIndex}
          onDragStart={onDragStart}
          allCourts={allCourts}
          playerGenders={playerGenders}
          restingPlayers={restingPlayers}
        />

        {showScores && (
          <ScoreInput
            court={court}
            scores={scores}
            onScoreChange={onScoreChange}
            onSubmitScore={onSubmitScore}
          />
        )}
      </div>
    </Card>
  );
};

export default CourtCard;

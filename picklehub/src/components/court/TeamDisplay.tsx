
import DraggablePlayer from "../DraggablePlayer";
import { Court } from "@/types/scheduler";

interface TeamDisplayProps {
  label: string;
  players: string[];
  teamType: 'team1' | 'team2';
  courtIndex: number;
  rotationIndex: number;
  onDragStart: (e: React.DragEvent, data: { 
    player: string; 
    teamType: 'team1' | 'team2';
    courtIndex: number;
    rotationIndex: number;
  }) => void;
  allCourts: Court[];
  playerGenders: { [key: string]: string };
  restingPlayers: string[];
}

const TeamDisplay = ({
  label,
  players,
  teamType,
  courtIndex,
  rotationIndex,
  onDragStart,
  allCourts,
  playerGenders,
  restingPlayers,
}: TeamDisplayProps) => {
  // Get all players from all courts in the current rotation
  const allRotationPlayers = (allCourts || []).reduce((acc: string[], court) => {
    return [...acc, ...(court.team1 || []), ...(court.team2 || [])];
  }, []);

  return (
    <div className="flex justify-between items-center p-3 rounded-lg border-2 border-muted/20 bg-accent/5 hover:bg-accent/10 transition-colors">
      <span className="text-sm font-semibold text-card-foreground bg-accent/20 px-2 py-1 rounded">{label}:</span>
      <span className="font-medium space-x-2">
        {(players || []).map((player, playerIdx) => (
          <DraggablePlayer
            key={playerIdx}
            player={player}
            gender={playerGenders[player] || 'M'}
            teamType={teamType}
            courtIndex={courtIndex}
            rotationIndex={rotationIndex}
            onDragStart={onDragStart}
            currentRotationPlayers={allRotationPlayers}
            restingPlayers={restingPlayers}
          />
        ))}
      </span>
    </div>
  );
};

export default TeamDisplay;

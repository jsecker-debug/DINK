
import { PlayerData } from "@/types/court-display";
import { Court } from "@/types/scheduler"; // Add this import
import DraggablePlayer from "../DraggablePlayer";

interface RestingPlayersProps {
  resters: string[];
  players: { [key: string]: PlayerData };
  rotationIndex: number;
  onDragStart: (e: React.DragEvent, data: { 
    player: string; 
    teamType: 'team1' | 'team2';
    courtIndex: number;
    rotationIndex: number;
  }) => void;
  allCourts: Court[];
}

const RestingPlayers = ({ 
  resters, 
  players,
  rotationIndex,
  onDragStart,
  allCourts,
}: RestingPlayersProps) => {
  if (resters.length === 0) return null;

  return (
    <div className="mt-6 p-4 bg-orange-50 dark:bg-orange-950/20 rounded-lg border-2 border-orange-200 dark:border-orange-800/30 shadow-sm">
      <div className="flex items-center gap-2 mb-3">
        <div className="w-3 h-3 bg-orange-500 rounded-full"></div>
        <span className="font-semibold text-orange-700 dark:text-orange-300 text-sm uppercase tracking-wide">Resting Players</span>
      </div>
      <div className="space-x-2">
        {resters.map((player, idx) => (
          <DraggablePlayer
            key={idx}
            player={player}
            gender={players[player]?.gender || 'M'}
            teamType="team1" // Default team type for resting players
            courtIndex={-1} // Special index for resting players
            rotationIndex={rotationIndex}
            onDragStart={onDragStart}
            currentRotationPlayers={allCourts.reduce((acc, court) => [...acc, ...court.team1, ...court.team2], [])}
            restingPlayers={resters}
          />
        ))}
      </div>
    </div>
  );
};

export default RestingPlayers;

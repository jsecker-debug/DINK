import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Repeat } from "lucide-react";

interface DraggablePlayerProps {
  player: string;
  gender: string;
  teamType: 'team1' | 'team2';
  courtIndex: number;
  rotationIndex: number;
  onDragStart: (e: React.DragEvent, data: { 
    player: string; 
    teamType: 'team1' | 'team2';
    courtIndex: number;
    rotationIndex: number;
    targetPlayer?: string;
  }) => void;
  currentRotationPlayers: string[];
  restingPlayers: string[];
}

const DraggablePlayer = ({ 
  player,
  gender,
  teamType,
  courtIndex,
  rotationIndex,
  onDragStart,
  currentRotationPlayers,
  restingPlayers,
}: DraggablePlayerProps) => {
  const handleClick = (targetPlayer: string) => {
    // Create a mock drag event since we're using clicks
    const mockEvent = new Event('mock') as unknown as React.DragEvent;
    onDragStart(mockEvent, { 
      player,
      teamType,
      courtIndex,
      rotationIndex,
      targetPlayer
    });
  };

  // Filter available players based on current player's position
  const getAvailablePlayers = () => {
    const allPlayers = [...currentRotationPlayers, ...restingPlayers];
    
    // Remove duplicates and current player
    return allPlayers.filter((p, index, self) => {
      const isDuplicate = self.indexOf(p) !== index;
      const isSamePlayer = p === player;
      
      if (courtIndex === -1) {
        // If current player is resting, show all players except other resting players
        return !isDuplicate && !isSamePlayer && !restingPlayers.includes(p);
      } else {
        // If current player is on court, show all players except those on the same team
        const currentTeamPlayers = courtIndex !== -1 && teamType === 'team1' 
          ? currentRotationPlayers.slice(courtIndex * 4, courtIndex * 4 + 2)  // Get team1 players for this court
          : currentRotationPlayers.slice(courtIndex * 4 + 2, courtIndex * 4 + 4);  // Get team2 players for this court
        
        return !isDuplicate && !isSamePlayer && !currentTeamPlayers.includes(p);
      }
    });
  };

  const availablePlayers = getAvailablePlayers();

  return (
    <TooltipProvider>
      <Tooltip>
        <DropdownMenu>
          <TooltipTrigger asChild>
            <DropdownMenuTrigger asChild>
              <button type="button" className="cursor-pointer select-none hover:bg-primary/10 hover:border-primary/20 px-3 py-2 rounded-md border-2 border-transparent bg-primary/5 inline-flex items-center gap-1 transition-all font-medium shadow-sm">
                <span className="text-card-foreground">{player}</span>
                <span className="text-xs text-muted-foreground font-normal">({gender})</span>
                <Repeat className="h-3 w-3 text-muted-foreground opacity-60" />
              </button>
            </DropdownMenuTrigger>
          </TooltipTrigger>
          <DropdownMenuContent 
            className="bg-card border-border z-50"
            align="end"
          >
            {availablePlayers.map((p) => (
              <DropdownMenuItem
                key={p}
                onClick={() => handleClick(p)}
                className="flex items-center gap-2"
              >
                <span>{p}</span>
              </DropdownMenuItem>
            ))}
          </DropdownMenuContent>
        </DropdownMenu>
        <TooltipContent>
          <p>Click to swap with another player</p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
};

export default DraggablePlayer;

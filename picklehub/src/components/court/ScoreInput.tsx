
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Court } from "@/types/scheduler";

interface ScoreInputProps {
  court: Court;
  scores: { team1: string; team2: string };
  onScoreChange: (team: 'team1' | 'team2', value: string) => void;
  onSubmitScore: () => void;
}

const ScoreInput = ({ court, scores, onScoreChange, onSubmitScore }: ScoreInputProps) => {
  return (
    <div className="mt-4 space-y-4">
      <div className="flex gap-4">
        <div className="flex-1">
          <Input
            type="number"
            placeholder="Team 1 Score"
            value={scores?.team1 || ''}
            onChange={(e) => onScoreChange('team1', e.target.value)}
            min="0"
            max="21"
          />
        </div>
        <div className="flex-1">
          <Input
            type="number"
            placeholder="Team 2 Score"
            value={scores?.team2 || ''}
            onChange={(e) => onScoreChange('team2', e.target.value)}
            min="0"
            max="21"
          />
        </div>
      </div>
      <Button 
        onClick={onSubmitScore}
        className="w-full"
      >
        Submit Score
      </Button>
    </div>
  );
};

export default ScoreInput;

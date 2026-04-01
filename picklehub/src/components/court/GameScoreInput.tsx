import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Label } from "@/components/ui/label";
import { Trash2, Plus } from "lucide-react";

interface GameScore {
  game_number: number;
  team1_score: number;
  team2_score: number;
}

interface GameScoreInputProps {
  courtNumber: number;
  team1Players: string[];
  team2Players: string[];
  existingScores?: GameScore[];
  onSaveScores: (scores: GameScore[]) => void;
  disabled?: boolean;
}

const GameScoreInput = ({ 
  courtNumber, 
  team1Players, 
  team2Players, 
  existingScores = [],
  onSaveScores,
  disabled = false
}: GameScoreInputProps) => {
  const [scores, setScores] = useState<GameScore[]>(
    existingScores.length > 0 
      ? existingScores 
      : [{ game_number: 1, team1_score: 0, team2_score: 0 }]
  );

  const updateScore = (gameIndex: number, team: 'team1' | 'team2', value: string) => {
    const numValue = parseInt(value) || 0;
    setScores(prev => prev.map((score, idx) => 
      idx === gameIndex 
        ? { ...score, [`${team}_score`]: numValue }
        : score
    ));
  };

  const addGame = () => {
    if (scores.length < 5) {
      setScores(prev => [...prev, { 
        game_number: prev.length + 1, 
        team1_score: 0, 
        team2_score: 0 
      }]);
    }
  };

  const removeGame = (gameIndex: number) => {
    if (scores.length > 1) {
      setScores(prev => prev
        .filter((_, idx) => idx !== gameIndex)
        .map((score, idx) => ({ ...score, game_number: idx + 1 }))
      );
    }
  };

  const handleSave = () => {
    const validScores = scores.filter(score => 
      score.team1_score > 0 || score.team2_score > 0
    );
    onSaveScores(validScores);
  };

  const getTeam1Wins = () => scores.filter(s => s.team1_score > s.team2_score).length;
  const getTeam2Wins = () => scores.filter(s => s.team2_score > s.team1_score).length;

  return (
    <Card className="p-4 bg-card border-border">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold">Court {courtNumber} Scores</h3>
          <div className="flex gap-2">
            <Badge variant="outline">
              Team 1: {getTeam1Wins()} wins
            </Badge>
            <Badge variant="outline">
              Team 2: {getTeam2Wins()} wins
            </Badge>
          </div>
        </div>

        {/* Team Names */}
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <Label className="font-medium">Team 1</Label>
            <div className="text-muted-foreground">
              {team1Players.join(" & ")}
            </div>
          </div>
          <div>
            <Label className="font-medium">Team 2</Label>
            <div className="text-muted-foreground">
              {team2Players.join(" & ")}
            </div>
          </div>
        </div>

        {/* Game Scores */}
        <div className="space-y-3">
          {scores.map((score, gameIndex) => (
            <div key={gameIndex} className="flex items-center gap-2">
              <Label className="w-16 text-sm">Game {score.game_number}:</Label>
              <Input
                type="number"
                placeholder="0"
                value={score.team1_score || ''}
                onChange={(e) => updateScore(gameIndex, 'team1', e.target.value)}
                className="w-20"
                min="0"
                disabled={disabled}
              />
              <span className="text-muted-foreground">-</span>
              <Input
                type="number"
                placeholder="0"
                value={score.team2_score || ''}
                onChange={(e) => updateScore(gameIndex, 'team2', e.target.value)}
                className="w-20"
                min="0"
                disabled={disabled}
              />
              {scores.length > 1 && !disabled && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => removeGame(gameIndex)}
                  className="p-1 h-8 w-8"
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              )}
            </div>
          ))}
        </div>

        {/* Add Game Button */}
        {scores.length < 5 && !disabled && (
          <Button
            variant="outline"
            size="sm"
            onClick={addGame}
            className="w-full"
          >
            <Plus className="h-4 w-4 mr-2" />
            Add Game (Best of {scores.length + 1})
          </Button>
        )}

        {/* Save Button */}
        {!disabled && (
          <Button 
            onClick={handleSave}
            className="w-full"
            disabled={scores.every(s => s.team1_score === 0 && s.team2_score === 0)}
          >
            Save Scores
          </Button>
        )}
      </div>
    </Card>
  );
};

export default GameScoreInput;
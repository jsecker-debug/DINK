
import { Button } from "@/components/ui/button";

interface GenerateButtonsProps {
  onGenerateSchedule: () => void;
  onGenerateKingCourt: () => void;
}

const GenerateButtons = ({ onGenerateSchedule, onGenerateKingCourt }: GenerateButtonsProps) => {
  return (
    <div className="flex flex-wrap gap-4 justify-center">
      <Button
        onClick={onGenerateSchedule}
        className="bg-primary hover:bg-primary/90"
      >
        Generate Random Schedule
      </Button>
      <Button
        onClick={onGenerateKingCourt}
        className="bg-secondary hover:bg-secondary/90"
      >
        Generate King of the Court
      </Button>
    </div>
  );
};

export default GenerateButtons;

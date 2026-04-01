
import { Button } from "@/components/ui/button";
import { UseMutationResult } from "@tanstack/react-query";

interface SaveScheduleButtonProps {
  selectedSession: string;
  saveScheduleMutation: UseMutationResult<void, Error, void, unknown>;
}

const SaveScheduleButton = ({ selectedSession, saveScheduleMutation }: SaveScheduleButtonProps) => {
  return (
    <Button 
      onClick={() => saveScheduleMutation.mutate()}
      disabled={!selectedSession || saveScheduleMutation.isPending}
      className="w-full"
    >
      {saveScheduleMutation.isPending ? "Saving..." : "Save to Session"}
    </Button>
  );
};

export default SaveScheduleButton;


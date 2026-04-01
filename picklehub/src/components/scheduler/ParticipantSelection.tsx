import { Checkbox } from "@/components/ui/checkbox";
import type { Participant } from "@/types/scheduler";

interface ParticipantSelectionProps {
  participants: Participant[] | undefined;
  selectedParticipants: string[];
  onParticipantToggle: (id: string, checked: boolean) => void;
}

const ParticipantSelection = ({
  participants,
  selectedParticipants,
  onParticipantToggle,
}: ParticipantSelectionProps) => {
  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      {participants?.map((participant) => (
        <div key={participant.id} className="flex items-center space-x-2">
          <Checkbox
            id={participant.id}
            checked={selectedParticipants.includes(participant.id)}
            onCheckedChange={(checked) => {
              onParticipantToggle(participant.id, !!checked);
            }}
          />
          <label
            htmlFor={participant.id}
            className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
          >
            {participant.name}
          </label>
        </div>
      ))}
    </div>
  );
};

export default ParticipantSelection;
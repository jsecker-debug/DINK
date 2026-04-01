
import { Textarea } from "@/components/ui/textarea";

interface TemporaryPlayersInputProps {
  value: string;
  onChange: (value: string) => void;
}

const TemporaryPlayersInput = ({ value, onChange }: TemporaryPlayersInputProps) => {
  return (
    <div>
      <h3 className="text-lg font-semibold mb-4">Add Temporary Players</h3>
      <Textarea
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Enter temporary player names, separated by commas or new lines"
        className="mb-4 min-h-[120px]"
      />
    </div>
  );
};

export default TemporaryPlayersInput;

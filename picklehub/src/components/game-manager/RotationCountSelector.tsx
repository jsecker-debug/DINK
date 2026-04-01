
import { Label } from "@/components/ui/label";
import { Slider } from "@/components/ui/slider";

interface RotationCountSelectorProps {
  value: number;
  onChange: (value: number) => void;
}

const RotationCountSelector = ({ value, onChange }: RotationCountSelectorProps) => {
  return (
    <div className="space-y-2">
      <div className="flex justify-between items-center">
        <Label htmlFor="rotation-count">Number of Rotations</Label>
        <span className="text-sm text-gray-500">{value}</span>
      </div>
      <Slider
        id="rotation-count"
        min={4}
        max={12}
        step={1}
        value={[value]}
        onValueChange={(values) => onChange(values[0])}
        className="w-full"
      />
    </div>
  );
};

export default RotationCountSelector;

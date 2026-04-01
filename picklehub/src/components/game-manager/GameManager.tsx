
import { useState } from "react";
import { toast } from "sonner";
import { Card } from "@/components/ui/card";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import CourtDisplay from "@/components/CourtDisplay";
import ParticipantSelection from "@/components/scheduler/ParticipantSelection";
import TemporaryPlayersInput from "@/components/scheduler/TemporaryPlayersInput";
import { useParticipants } from "@/hooks/useParticipants";
import { useSessions } from "@/hooks/useSessions";
import SessionSelect from "./SessionSelect";
import SaveScheduleButton from "./SaveScheduleButton";
import { useGameSchedule } from "@/hooks/useGameSchedule";
import { useScheduleGeneration } from "@/hooks/useScheduleGeneration";
import DownloadPdfButton from "@/components/DownloadPdfButton";
import RotationCountSelector from "./RotationCountSelector";

const GameManager = () => {
  const [temporaryPlayers, setTemporaryPlayers] = useState("");
  const [selectedParticipants, setSelectedParticipants] = useState<string[]>([]);
  const [selectedSession, setSelectedSession] = useState<string>("");
  const [rotationCount, setRotationCount] = useState(8);

  const { data: participants } = useParticipants();
  const { data: sessions } = useSessions();

  const {
    rotations,
    setRotations,
    kingCourtRotation,
    setKingCourtRotation,
    saveScheduleMutation
  } = useGameSchedule(selectedSession);

  const { generateSchedule } = useScheduleGeneration({
    temporaryPlayers,
    selectedParticipants,
    participants,
    setRotations,
    setKingCourtRotation,
    rotationCount
  });

  const handleClear = () => {
    setTemporaryPlayers("");
    setSelectedParticipants([]);
    setRotations([]);
    setKingCourtRotation(null);
    setSelectedSession("");
    setRotationCount(8);
    toast.success("All fields cleared");
  };

  return (
    <Card className="p-6 mb-6">
      <div className="mb-6">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold">Select Participants</h3>
          <Button
            variant="outline"
            size="sm"
            onClick={handleClear}
            className="gap-2"
          >
            <X className="h-4 w-4" />
            Clear All
          </Button>
        </div>
        <ParticipantSelection
          participants={participants}
          selectedParticipants={selectedParticipants}
          onParticipantToggle={(id, checked) => {
            setSelectedParticipants(prev =>
              checked
                ? [...prev, id]
                : prev.filter(pid => pid !== id)
            );
          }}
        />
      </div>

      <TemporaryPlayersInput
        value={temporaryPlayers}
        onChange={setTemporaryPlayers}
      />

      <div className="space-y-4 mb-6">
        <RotationCountSelector 
          value={rotationCount}
          onChange={setRotationCount}
        />
        
        <Button
          onClick={generateSchedule}
          className="w-full bg-primary hover:bg-primary/90"
        >
          Generate Schedule
        </Button>
      </div>

      {rotations.length > 0 && (
        <div id="schedule-content">
          <CourtDisplay rotations={rotations} isKingCourt={false} />
        </div>
      )}

      {kingCourtRotation && (
        <div className="mt-8" id="king-court-content">
          <CourtDisplay rotations={[kingCourtRotation]} isKingCourt={true} />
        </div>
      )}

      {(rotations.length > 0 || kingCourtRotation) && (
        <>
          <div className="mt-8 mb-8">
            <DownloadPdfButton
              contentId="schedule-content"
              fileName="pickleball-schedule"
              className="w-full"
            />
          </div>

          <div className="space-y-4">
            <SessionSelect 
              sessions={sessions}
              selectedSession={selectedSession}
              setSelectedSession={setSelectedSession}
            />
            <SaveScheduleButton 
              selectedSession={selectedSession}
              saveScheduleMutation={saveScheduleMutation}
            />
          </div>
        </>
      )}
    </Card>
  );
};

export default GameManager;

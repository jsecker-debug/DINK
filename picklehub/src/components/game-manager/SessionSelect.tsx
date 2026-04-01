import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { Session } from "@/types/scheduler";

interface SessionSelectProps {
  sessions: Session[] | undefined;
  selectedSession: string;
  setSelectedSession: (sessionId: string) => void;
}

const SessionSelect = ({ sessions, selectedSession, setSelectedSession }: SessionSelectProps) => {
  const availableSessions = sessions?.filter(session => 
    new Date(session.Date) > new Date() && session.Status !== 'Ready'
  ) || [];

  return (
    <div className="space-y-2">
      <label className="text-sm font-medium">Select Session to Save Schedule</label>
      <Select 
        value={selectedSession} 
        onValueChange={setSelectedSession}
      >
        <SelectTrigger>
          <SelectValue placeholder="Select a session" />
        </SelectTrigger>
        <SelectContent>
          {availableSessions.map((session) => (
            <SelectItem key={session.id} value={session.id}>
              {new Date(session.Date).toLocaleDateString()} - {session.Venue}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
};

export default SessionSelect;
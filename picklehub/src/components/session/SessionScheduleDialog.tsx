import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { 
  Calendar, 
  Users, 
  Clock, 
  Play, 
  Settings,
  Info,
  CheckCircle
} from "lucide-react";
import { useSessionScheduleGeneration } from "@/hooks/useSessionScheduleGeneration";
import { SessionRegistrationWithUser } from "@/hooks/useSessionRegistration";
import { useTemporaryParticipants } from "@/hooks/useTemporaryParticipants";
import CourtDisplay from "@/components/CourtDisplay";

interface SessionScheduleDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  sessionId: string;
  registeredUsers: SessionRegistrationWithUser[];
  sessionStatus: string;
}

const SessionScheduleDialog = ({
  open,
  onOpenChange,
  sessionId,
  registeredUsers,
  sessionStatus
}: SessionScheduleDialogProps) => {
  const [currentStep, setCurrentStep] = useState<'settings' | 'preview' | 'generated'>('settings');
  
  const { data: temporaryParticipants = [] } = useTemporaryParticipants(sessionId);
  
  const {
    rotations,
    scheduleSettings,
    setScheduleSettings,
    generateSessionSchedule,
    saveScheduleMutation,
    totalPlayers
  } = useSessionScheduleGeneration({
    sessionId,
    registeredUsers
  });

  const handleSettingsChange = (field: 'courts' | 'rounds', value: number) => {
    setScheduleSettings(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleGenerate = () => {
    generateSessionSchedule();
    setCurrentStep('generated');
  };

  const handleSave = () => {
    saveScheduleMutation.mutate();
  };

  const handleClose = () => {
    setCurrentStep('settings');
    onOpenChange(false);
  };

  const maxPlayersPerRound = scheduleSettings.courts * 4;
  const restingPlayersPerRound = Math.max(0, totalPlayers - maxPlayersPerRound);

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Play className="h-5 w-5" />
            Generate Session Schedule
          </DialogTitle>
          <DialogDescription>
            Create a fair rotation schedule for all registered players
          </DialogDescription>
        </DialogHeader>

        {currentStep === 'settings' && (
          <div className="space-y-6">
            {/* Player Summary */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Users className="h-4 w-4" />
                  All Players ({totalPlayers})
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Registered Users */}
                {registeredUsers.filter(user => user.status === 'registered').length > 0 && (
                  <div>
                    <h5 className="text-sm font-medium text-muted-foreground mb-2">
                      Registered Users ({registeredUsers.filter(user => user.status === 'registered').length})
                    </h5>
                    <div className="flex flex-wrap gap-2">
                      {registeredUsers
                        .filter(user => user.status === 'registered')
                        .map(user => (
                          <Badge key={user.id} variant="default">
                            {user.user_profiles?.first_name && user.user_profiles?.last_name 
                              ? `${user.user_profiles.first_name} ${user.user_profiles.last_name}`
                              : user.user_profiles?.first_name || 'Unknown Player'
                            }
                            {user.user_profiles?.skill_level && (
                              <span className="ml-1 text-xs">({user.user_profiles.skill_level})</span>
                            )}
                          </Badge>
                        ))}
                    </div>
                  </div>
                )}

                {/* Temporary Participants */}
                {temporaryParticipants.length > 0 && (
                  <div>
                    <h5 className="text-sm font-medium text-muted-foreground mb-2">
                      Temporary Participants ({temporaryParticipants.length})
                    </h5>
                    <div className="flex flex-wrap gap-2">
                      {temporaryParticipants.map(temp => (
                        <Badge key={temp.id} variant="secondary">
                          {temp.name}
                          <span className="ml-1 text-xs">({temp.skill_level})</span>
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}

                {totalPlayers === 0 && (
                  <p className="text-sm text-muted-foreground">No players added to this session yet.</p>
                )}
              </CardContent>
            </Card>

            {/* Schedule Settings */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Settings className="h-4 w-4" />
                  Schedule Settings
                </CardTitle>
                <CardDescription>
                  Configure the number of courts and rounds for your session
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="courts">Number of Courts</Label>
                    <Input
                      id="courts"
                      type="number"
                      min="1"
                      max="10"
                      value={scheduleSettings.courts}
                      onChange={(e) => handleSettingsChange('courts', parseInt(e.target.value) || 1)}
                    />
                    <p className="text-xs text-muted-foreground">
                      Each court holds 4 players (2v2)
                    </p>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="rounds">Number of Rounds</Label>
                    <Input
                      id="rounds"
                      type="number"
                      min="1"
                      max="20"
                      value={scheduleSettings.rounds}
                      onChange={(e) => handleSettingsChange('rounds', parseInt(e.target.value) || 1)}
                    />
                    <p className="text-xs text-muted-foreground">
                      Total games to be played
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Schedule Preview */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Info className="h-4 w-4" />
                  Schedule Preview
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                  <div className="flex items-center gap-2">
                    <Calendar className="h-4 w-4 text-blue-500" />
                    <div>
                      <p className="font-medium">{scheduleSettings.rounds} Rounds</p>
                      <p className="text-muted-foreground">Total games</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Users className="h-4 w-4 text-green-500" />
                    <div>
                      <p className="font-medium">{maxPlayersPerRound} Playing</p>
                      <p className="text-muted-foreground">Per round</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Clock className="h-4 w-4 text-orange-500" />
                    <div>
                      <p className="font-medium">{restingPlayersPerRound} Resting</p>
                      <p className="text-muted-foreground">Per round</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Play className="h-4 w-4 text-purple-500" />
                    <div>
                      <p className="font-medium">{scheduleSettings.courts} Courts</p>
                      <p className="text-muted-foreground">Available</p>
                    </div>
                  </div>
                </div>
                
                {totalPlayers < maxPlayersPerRound && (
                  <div className="mt-4 p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
                    <p className="text-sm text-yellow-800">
                      <strong>Warning:</strong> You need at least {maxPlayersPerRound} players for {scheduleSettings.courts} courts. 
                      Consider reducing the number of courts or adding more players.
                    </p>
                  </div>
                )}
                
                {restingPlayersPerRound > 0 && (
                  <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                    <p className="text-sm text-blue-800">
                      <strong>Note:</strong> {restingPlayersPerRound} player(s) will rest each round. 
                      Rest periods will be distributed fairly across all players.
                    </p>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        )}

        {currentStep === 'generated' && rotations.length > 0 && (
          <div className="space-y-4">
            <div className="flex items-center gap-2 p-4 bg-green-50 border border-green-200 rounded-lg">
              <CheckCircle className="h-5 w-5 text-green-600" />
              <div>
                <p className="font-medium text-green-800">Schedule Generated Successfully!</p>
                <p className="text-sm text-green-700">
                  Created {rotations.length} rounds with fair player rotation and rest distribution.
                </p>
              </div>
            </div>
            
            <div className="max-h-96 overflow-y-auto">
              <CourtDisplay 
                rotations={rotations} 
                isKingCourt={false}
                sessionId={sessionId}
                sessionStatus={sessionStatus}
              />
            </div>
          </div>
        )}

        <DialogFooter className="flex justify-between">
          <Button variant="outline" onClick={handleClose}>
            Cancel
          </Button>
          
          <div className="flex gap-2">
            {currentStep === 'settings' && (
              <Button 
                onClick={handleGenerate}
                disabled={totalPlayers < maxPlayersPerRound}
              >
                Generate Schedule
              </Button>
            )}
            
            {currentStep === 'generated' && (
              <>
                <Button 
                  variant="outline" 
                  onClick={() => setCurrentStep('settings')}
                >
                  Back to Settings
                </Button>
                <Button 
                  onClick={handleSave}
                  disabled={saveScheduleMutation.isPending}
                >
                  {saveScheduleMutation.isPending ? 'Saving...' : 'Save Schedule'}
                </Button>
              </>
            )}
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default SessionScheduleDialog;
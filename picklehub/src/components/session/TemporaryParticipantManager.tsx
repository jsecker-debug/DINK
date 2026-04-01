import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { 
  UserPlus, 
  X, 
  Edit2, 
  Users, 
  Phone,
  Target,
  FileText
} from "lucide-react";
import { 
  useTemporaryParticipants, 
  useAddTemporaryParticipant, 
  useRemoveTemporaryParticipant,
  useUpdateTemporaryParticipant,
  TemporaryParticipant
} from "@/hooks/useTemporaryParticipants";

interface TemporaryParticipantManagerProps {
  sessionId: string;
}

const TemporaryParticipantManager = ({ sessionId }: TemporaryParticipantManagerProps) => {
  const [addDialogOpen, setAddDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [editingParticipant, setEditingParticipant] = useState<TemporaryParticipant | null>(null);
  
  const [newParticipant, setNewParticipant] = useState({
    name: "",
    skill_level: 3.0,
    phone: "",
    notes: ""
  });

  const { data: temporaryParticipants = [] } = useTemporaryParticipants(sessionId);
  const addMutation = useAddTemporaryParticipant();
  const removeMutation = useRemoveTemporaryParticipant();
  const updateMutation = useUpdateTemporaryParticipant();

  const handleAddParticipant = () => {
    if (!newParticipant.name.trim()) {
      return;
    }

    addMutation.mutate(
      {
        sessionId,
        participant: newParticipant
      },
      {
        onSuccess: () => {
          setNewParticipant({
            name: "",
            skill_level: 3.0,
            phone: "",
            notes: ""
          });
          setAddDialogOpen(false);
        }
      }
    );
  };

  const handleRemoveParticipant = (participantId: string) => {
    if (confirm("Are you sure you want to remove this temporary participant?")) {
      removeMutation.mutate({
        participantId,
        sessionId
      });
    }
  };

  const handleEditParticipant = (participant: TemporaryParticipant) => {
    setEditingParticipant(participant);
    setEditDialogOpen(true);
  };

  const handleUpdateParticipant = () => {
    if (!editingParticipant) return;

    updateMutation.mutate(
      {
        participantId: editingParticipant.id,
        sessionId,
        updates: {
          name: editingParticipant.name,
          skill_level: editingParticipant.skill_level,
          phone: editingParticipant.phone,
          notes: editingParticipant.notes
        }
      },
      {
        onSuccess: () => {
          setEditDialogOpen(false);
          setEditingParticipant(null);
        }
      }
    );
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Users className="h-4 w-4" />
          <h4 className="text-sm font-medium text-muted-foreground">
            Temporary Participants ({temporaryParticipants.length})
          </h4>
        </div>
        
        <Dialog open={addDialogOpen} onOpenChange={setAddDialogOpen}>
          <DialogTrigger asChild>
            <Button variant="outline" size="sm">
              <UserPlus className="h-4 w-4 mr-2" />
              Add Temporary
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Add Temporary Participant</DialogTitle>
              <DialogDescription>
                Add someone without an account to this session
              </DialogDescription>
            </DialogHeader>
            
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="temp-name">Name *</Label>
                <Input
                  id="temp-name"
                  placeholder="Full name"
                  value={newParticipant.name}
                  onChange={(e) => setNewParticipant(prev => ({ ...prev, name: e.target.value }))}
                />
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="temp-skill">Skill Level</Label>
                <Select
                  value={newParticipant.skill_level.toString()}
                  onValueChange={(value) => setNewParticipant(prev => ({ ...prev, skill_level: parseFloat(value) }))}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select skill level" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="2.0">2.0 - Beginner</SelectItem>
                    <SelectItem value="2.5">2.5 - Beginner+</SelectItem>
                    <SelectItem value="3.0">3.0 - Intermediate</SelectItem>
                    <SelectItem value="3.5">3.5 - Intermediate+</SelectItem>
                    <SelectItem value="4.0">4.0 - Advanced</SelectItem>
                    <SelectItem value="4.5">4.5 - Advanced+</SelectItem>
                    <SelectItem value="5.0">5.0 - Expert</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="temp-phone">Phone (Optional)</Label>
                <Input
                  id="temp-phone"
                  placeholder="Phone number"
                  value={newParticipant.phone}
                  onChange={(e) => setNewParticipant(prev => ({ ...prev, phone: e.target.value }))}
                />
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="temp-notes">Notes (Optional)</Label>
                <Textarea
                  id="temp-notes"
                  placeholder="Any additional notes"
                  value={newParticipant.notes}
                  onChange={(e) => setNewParticipant(prev => ({ ...prev, notes: e.target.value }))}
                  rows={2}
                />
              </div>
            </div>
            
            <DialogFooter>
              <Button variant="outline" onClick={() => setAddDialogOpen(false)}>
                Cancel
              </Button>
              <Button 
                onClick={handleAddParticipant}
                disabled={!newParticipant.name.trim() || addMutation.isPending}
              >
                {addMutation.isPending ? 'Adding...' : 'Add Participant'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {temporaryParticipants.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {temporaryParticipants.map((participant) => (
            <div
              key={participant.id}
              className="flex items-center justify-between p-3 border border-border rounded-lg bg-accent/5"
            >
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white text-sm font-bold">
                  {participant.name.split(' ').map(n => n[0]).join('').toUpperCase()}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-card-foreground truncate">{participant.name}</p>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <Target className="h-3 w-3" />
                    Level {participant.skill_level}
                    {participant.phone && (
                      <>
                        <Phone className="h-3 w-3 ml-1" />
                        <span className="truncate max-w-20">{participant.phone}</span>
                      </>
                    )}
                  </div>
                  {participant.notes && (
                    <div className="flex items-center gap-1 text-xs text-muted-foreground mt-1">
                      <FileText className="h-3 w-3" />
                      <span className="truncate">{participant.notes}</span>
                    </div>
                  )}
                </div>
              </div>
              <div className="flex items-center gap-1">
                <Badge variant="secondary" className="text-xs">
                  Temp
                </Badge>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => handleEditParticipant(participant)}
                  className="h-6 w-6 p-0"
                >
                  <Edit2 className="h-3 w-3" />
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => handleRemoveParticipant(participant.id)}
                  disabled={removeMutation.isPending}
                  className="h-6 w-6 p-0 text-red-500 hover:text-red-700"
                >
                  <X className="h-3 w-3" />
                </Button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Edit Dialog */}
      <Dialog open={editDialogOpen} onOpenChange={setEditDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Temporary Participant</DialogTitle>
            <DialogDescription>
              Update participant information
            </DialogDescription>
          </DialogHeader>
          
          {editingParticipant && (
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="edit-name">Name *</Label>
                <Input
                  id="edit-name"
                  value={editingParticipant.name}
                  onChange={(e) => setEditingParticipant(prev => prev ? { ...prev, name: e.target.value } : null)}
                />
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="edit-skill">Skill Level</Label>
                <Select
                  value={editingParticipant.skill_level.toString()}
                  onValueChange={(value) => setEditingParticipant(prev => prev ? { ...prev, skill_level: parseFloat(value) } : null)}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="2.0">2.0 - Beginner</SelectItem>
                    <SelectItem value="2.5">2.5 - Beginner+</SelectItem>
                    <SelectItem value="3.0">3.0 - Intermediate</SelectItem>
                    <SelectItem value="3.5">3.5 - Intermediate+</SelectItem>
                    <SelectItem value="4.0">4.0 - Advanced</SelectItem>
                    <SelectItem value="4.5">4.5 - Advanced+</SelectItem>
                    <SelectItem value="5.0">5.0 - Expert</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="edit-phone">Phone</Label>
                <Input
                  id="edit-phone"
                  value={editingParticipant.phone || ""}
                  onChange={(e) => setEditingParticipant(prev => prev ? { ...prev, phone: e.target.value } : null)}
                />
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="edit-notes">Notes</Label>
                <Textarea
                  id="edit-notes"
                  value={editingParticipant.notes || ""}
                  onChange={(e) => setEditingParticipant(prev => prev ? { ...prev, notes: e.target.value } : null)}
                  rows={2}
                />
              </div>
            </div>
          )}
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setEditDialogOpen(false)}>
              Cancel
            </Button>
            <Button 
              onClick={handleUpdateParticipant}
              disabled={!editingParticipant?.name.trim() || updateMutation.isPending}
            >
              {updateMutation.isPending ? 'Updating...' : 'Update'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default TemporaryParticipantManager;
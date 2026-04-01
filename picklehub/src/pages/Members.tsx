import { AddParticipantDialog } from "@/components/AddParticipantDialog";
import { ParticipantsList } from "@/components/participants/ParticipantsList";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useState } from "react";
import { useClubMembers, type ClubMember } from "@/hooks/useClubMembers";
import { useClub } from "@/contexts/ClubContext";
import { Search, UserPlus, Users, Trophy, Activity, Crown } from "lucide-react";

const Members = () => {
  const [searchInput, setSearchInput] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const { selectedClub } = useClub();
  const { data: members, isLoading, error } = useClubMembers();

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setSearchQuery(searchInput);
  };

  const handleClearSearch = () => {
    setSearchInput("");
    setSearchQuery("");
  };

  // Calculate member stats
  const totalMembers = members?.length || 0;
  const activeMembers = members?.filter(m => (m.total_games_played || 0) > 0).length || 0;
  const newMembers = members?.filter(m => (m.total_games_played || 0) === 0).length || 0;
  const averageLevel = members?.length 
    ? (members.reduce((sum, m) => sum + (m.level || 0), 0) / members.length).toFixed(1)
    : "0.0";
  
  // Filter members based on search
  const filteredMembers = members?.filter(member => {
    if (!searchQuery) return true;
    const fullName = member.user_metadata?.full_name || '';
    const email = member.user_metadata?.email || '';
    return fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
           email.toLowerCase().includes(searchQuery.toLowerCase());
  }) || [];

  return (
    <div className="h-full">
      <div className="max-w-full mx-auto">
        <div className="mb-8 flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-foreground font-anybody">Members</h1>
            <p className="text-muted-foreground mt-2">Manage your club members</p>
          </div>
          <AddParticipantDialog />
        </div>

        {/* Member Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card className="p-6 bg-card border-border">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Total Members</p>
                <p className="text-2xl font-bold text-card-foreground">{totalMembers}</p>
              </div>
              <Users className="h-8 w-8 text-chart-1" />
            </div>
          </Card>
          
          <Card className="p-6 bg-card border-border">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Active Players</p>
                <p className="text-2xl font-bold text-card-foreground">{activeMembers}</p>
              </div>
              <Activity className="h-8 w-8 text-chart-2" />
            </div>
          </Card>
          
          <Card className="p-6 bg-card border-border">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">New Members</p>
                <p className="text-2xl font-bold text-card-foreground">{newMembers}</p>
              </div>
              <UserPlus className="h-8 w-8 text-chart-3" />
            </div>
          </Card>
          
          <Card className="p-6 bg-card border-border">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Avg Level</p>
                <p className="text-2xl font-bold text-card-foreground">{averageLevel}</p>
              </div>
              <Trophy className="h-8 w-8 text-chart-4" />
            </div>
          </Card>
        </div>

        {/* Search and Filter */}
        <div className="flex flex-col md:flex-row gap-4 mb-8">
          <div className="w-full md:flex-1">
            <Card className="p-6 bg-card border-border">
              <form onSubmit={handleSearch} className="space-y-4">
                <div className="flex flex-col sm:flex-row gap-4">
                  <div className="relative flex-1">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      value={searchInput}
                      onChange={(e) => setSearchInput(e.target.value)}
                      placeholder="Search members by name, level, or stats..."
                      className="pl-10 bg-background border-input"
                    />
                  </div>
                  <div className="flex gap-2">
                    <Button type="submit" className="flex-1 sm:flex-none">
                      Search
                    </Button>
                    <Button 
                      type="button" 
                      variant="outline"
                      onClick={handleClearSearch}
                      className="flex-1 sm:flex-none"
                    >
                      Clear
                    </Button>
                  </div>
                </div>
              </form>
            </Card>
          </div>
        </div>

        {/* Filter Badges */}
        <div className="flex flex-wrap gap-2 mb-6">
          <Badge variant="outline" className="cursor-pointer hover:bg-accent">
            All Members
          </Badge>
          <Badge variant="outline" className="cursor-pointer hover:bg-accent">
            Active Players
          </Badge>
          <Badge variant="outline" className="cursor-pointer hover:bg-accent">
            New Members
          </Badge>
          <Badge variant="outline" className="cursor-pointer hover:bg-accent">
            Level 2-3
          </Badge>
          <Badge variant="outline" className="cursor-pointer hover:bg-accent">
            Level 4-5
          </Badge>
          <Badge variant="outline" className="cursor-pointer hover:bg-accent">
            Level 6+
          </Badge>
        </div>

        {/* Members List */}
        <Card className="bg-card border-border">
          <div className="p-6">
            <h2 className="text-xl font-semibold text-card-foreground mb-4">
              Member Directory {selectedClub && `- ${selectedClub.name}`}
            </h2>
            
            {isLoading ? (
              <div className="text-center py-8">
                <div className="text-muted-foreground">Loading members...</div>
              </div>
            ) : error ? (
              <div className="text-center py-8">
                <div className="text-destructive">Failed to load members</div>
              </div>
            ) : !selectedClub ? (
              <div className="text-center py-8">
                <div className="text-muted-foreground">Please select a club to view members</div>
              </div>
            ) : filteredMembers.length === 0 ? (
              <div className="text-center py-8">
                <div className="text-muted-foreground">
                  {searchQuery ? 'No members found matching your search' : 'No members in this club yet'}
                </div>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {filteredMembers.map((member) => (
                  <div key={member.id} className="p-4 border border-border rounded-lg bg-background hover:bg-accent/50 transition-colors">
                    <div className="flex items-start justify-between mb-3">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <h3 className="font-semibold text-foreground">
                            {member.user_metadata?.full_name || 'Unknown Member'}
                          </h3>
                          {member.role === 'admin' && (
                            <Crown className="h-4 w-4 text-primary" />
                          )}
                        </div>
                        <p className="text-sm text-muted-foreground">
                          {member.user_metadata?.email}
                        </p>
                      </div>
                      <Badge variant={member.role === 'admin' ? 'default' : 'secondary'}>
                        {member.role === 'admin' ? 'Admin' : 'Member'}
                      </Badge>
                    </div>
                    
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span className="text-muted-foreground">Level:</span>
                        <span className="font-medium">{member.level}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-muted-foreground">Games:</span>
                        <span className="font-medium">{member.total_games_played}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-muted-foreground">Win Rate:</span>
                        <span className="font-medium">
                          {member.total_games_played && member.total_games_played > 0 
                            ? `${Math.round(((member.wins || 0) / member.total_games_played) * 100)}%`
                            : 'N/A'
                          }
                        </span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-muted-foreground">Joined:</span>
                        <span className="font-medium">
                          {new Date(member.joined_at).toLocaleDateString()}
                        </span>
                      </div>
                    </div>
                    
                    {member.profile?.phone && (
                      <div className="mt-3 pt-3 border-t border-border">
                        <p className="text-xs text-muted-foreground">
                          📞 {member.profile.phone}
                        </p>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        </Card>
      </div>
    </div>
  );
};

export default Members;
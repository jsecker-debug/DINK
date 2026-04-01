
export const parsePlayers = (temporaryPlayers: string, selectedParticipants: string[], participants: { id: string; name: string; }[]) => {
  const temporary = temporaryPlayers.split(/[\n,]/).map(s => s.trim()).filter(s => s !== "");
  const selected = participants
    ?.filter(p => selectedParticipants.includes(p.id))
    .map(p => p.name) || [];
  return [...selected, ...temporary];
};

export const shuffle = (array: any[]) => {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
};

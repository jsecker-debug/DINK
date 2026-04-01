
interface PlayerStatsProps {
  totalGames: number
  wins: number
  losses: number
}

export function PlayerStats({ totalGames, wins, losses }: PlayerStatsProps) {
  return (
    <div className="mt-8">
      <h3 className="text-lg font-medium text-gray-900 mb-4">Statistics</h3>
      <div className="grid grid-cols-2 gap-4 mb-8">
        <div>
          <p className="text-sm text-gray-500">Total Games</p>
          <p className="text-lg font-medium">{totalGames}</p>
        </div>
        <div>
          <p className="text-sm text-gray-500">Win/Loss Record</p>
          <p className="text-lg font-medium">{wins}/{losses}</p>
        </div>
      </div>
    </div>
  )
}

class Player {
    [int]$Number
    [string]$Mark
    [string]$Color
    [string]$Type

    Player (
        [int]$n,
        [string]$s,
        [string]$c,
        [string]$t
    ) {
        $this.Number = $n
        $this.Mark = $s
        $this.Color = $c
        $this.Type = $t
    }
}


class WinCondition {
    [int[]]$Matches
    [int[]]$UserPositions
    [int[]]$ComputerPositions
    [string]$Status

    WinCondition (
        [int[]]$m,
        [int[]]$up,
        [int[]]$cp,
        [string]$s
    ) {
        $this.Matches = $m
        $this.UserPositions = $up
        $this.ComputerPositions = $cp
        $this.Status = $s
    }
}


function TicTacToe {
    Out-GameStart

    [string[]]$positions = "not used", "1", "2", "3", "4", "5", "6", "7", "8", "9"
    $gameOn = $true
    $movesMade = 0

    $Global:winConditions = Get-WinConditions

    $numPlayers = Get-NumberOfPlayers

    if ($numPlayers -eq 1) {
        $players = Get-PlayerAndComputerMarks
    }
    else {
        [Player[]]$players = @([Player]::new(1, "X", "Cyan", "User"), [Player]::new(2, "O", "Yellow", "User"))
    }

    while ($gameOn) {
        $currentPlayer = $movesMade % 2
        
        if ($players[$currentPlayer].Type -eq "User") {
            $playerInput = Get-PlayerInput $positions $players[$currentPlayer]
            if ($numPlayers -eq 1) {
                $winConditions = Update-WinConditions $winConditions $players[$currentPlayer] $playerInput
            }
        }
        else {
            $playerInput = Get-ComputerMove $players[$currentPlayer] $winConditions $movesMade $positions $playerInput
            $winConditions = Update-WinConditions $winConditions $players[$currentPlayer] $playerInput
            $computerMoves += $playerInput
        }
        
        $positions[$playerInput] = $($players[$currentPlayer].Mark)
        $movesMade++
        
        Write-Game $positions

        $gameOn = Get-GameContinue $winConditions $positions $playerInput

        if ($movesMade -gt 8 -and $gameOn) {
            Write-Host "`nIt's a tie!`n`n" -ForegroundColor "Red"
                    
            return
        }
    }

    if ($players[$currentPlayer].Type -eq "User") {
        Write-Host "`nCongratulations Player $($players[(++$movesMade % 2)].Number)! You win!`n`n" -ForegroundColor "Green"
    }
    else {
        Write-Host "`nGood game Player $($players[($movesMade % 2)].Number). Computer wins!`n`n" -ForegroundColor "Red"
    }
}


function Get-WinConditions {
    [WinCondition[]]$winConditions = @(
        [WinCondition]::new(@(1, 2, 3), @(), @(), "Available"),
        [WinCondition]::new(@(4, 5, 6), @(), @(), "Available"),
        [WinCondition]::new(@(7, 8, 9), @(), @(), "Available"),
        [WinCondition]::new(@(1, 4, 7), @(), @(), "Available"),
        [WinCondition]::new(@(2, 5, 8), @(), @(), "Available"),
        [WinCondition]::new(@(3, 6, 9), @(), @(), "Available"),
        [WinCondition]::new(@(1, 5, 9), @(), @(), "Available"),
        [WinCondition]::new(@(3, 5, 7), @(), @(), "Available")
    )
    
    return $winConditions
}


function Out-GameStart {
    Write-Host "`n                      -------------------------" -ForegroundColor "Magenta"
    Write-Host "                      | Welcome to TicTacToe! |" -ForegroundColor "Magenta"
    Write-Host "                      -------------------------`n" -ForegroundColor "Magenta"

    Write-Host "========================= Rules of the Game =========================`n" -ForegroundColor "DarkGreen"
    
    Write-Host "Player 1 will be X." -ForegroundColor "Cyan"
    Write-Host "Player 2 will be O.`n`n" -ForegroundColor "Yellow"

    Write-Host "The player with X will begin."
    Write-Host "Each player will choose a position to place their mark on their turn."

    Write-Host "`n 1 | 2 | 3 "
    Write-Host "-----------"
    Write-Host " 4 | 5 | 6 "
    Write-Host "-----------"
    Write-Host " 7 | 8 | 9 `n"

    Write-Host "Game ends when a player has 3 of their marks in a row.`n"

    Write-Host "=====================================================================`n`n" -ForegroundColor "DarkGreen"
}


function Get-NumberOfPlayers {
    while ($true) {
        Write-Host "You can play a 1 Player or 2 Player game." -ForegroundColor "Magenta"
        Write-Host "How many Players?: " -NoNewLine -ForegroundColor "Magenta"
        $numPlayers = Read-Host

        if ($numPlayers -notmatch "^[12]{1}$") {
            Write-Host "`nInvalid number of players.`n" -ForegroundColor "Red"
        }
        else {
            break
        }
    }

    Write-Host "`n`n>>>>>>>>>>>>>>>>>>>>>>>>>>> $numPlayers Player Game <<<<<<<<<<<<<<<<<<<<<<<<<<<`n`n" -ForegroundColor "DarkGreen"

    return [int]$numPlayers
}


function Get-PlayerAndComputerMarks {
    while ($true) {
        Write-Host "You can be Player 1 (X) or Player 2 (O)." -ForegroundColor "Magenta"
        Write-Host "Which would you like to be? (X/O): " -NoNewLine -ForegroundColor "Magenta"
        $mark = Read-Host 
        Write-Host "`n"
        
        if ($mark -eq "X") {
            [Player[]]$players = @([Player]::new(1, "X", "Cyan", "User"), [Player]::new(2, "O", "Yellow", "Computer"))

            break
        }
        elseif ($mark -eq "O") {
            [Player[]]$players = @([Player]::new(1, "X", "Cyan", "Computer"), [Player]::new(2, "O", "Yellow", "User"))

            break
        }
        else {
            Write-Host "Invalid mark`n" -ForegroundColor "Red"
        }
    }

    return $players
}


function Get-PlayerInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]
        $positions,
        [Parameter(Mandatory)]
        [Player]
        $player
    )

    $validPlayerInput = $false

    while (!$validPlayerInput) {
        Write-Host "Player $($player.Number), please choose an available position." -ForegroundColor $player.Color

        try {
            Write-Host "$($player.Mark) Position: " -NoNewline -ForegroundColor $player.Color
            $playerInput = [int](Read-Host)

            if ($playerInput -lt 1 -or $playerInput -gt 9) {
                Write-Host "`nInvalid position`n" -ForegroundColor "Red"
            }
            elseif ($playerInput -ne $positions[$playerInput]) {
                Write-Host "`nUnavailable position`n" -ForegroundColor "Red"
            }
            else {
                $validPlayerInput = $true
            }
        }
        catch {
            Write-Host "`nInvalid position`n" -ForegroundColor "Red"
        }
    }

    return $playerInput
}


function Write-Game {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]
        $positions
    )

    Write-Host
    Out-Position $positions 1
    Write-Host "|" -NoNewLine
    Out-Position $positions 2
    Write-Host "|" -NoNewLine
    Out-Position $positions 3
    Write-Host "`n-----------"
    Out-Position $positions 4
    Write-Host "|" -NoNewLine
    Out-Position $positions 5
    Write-Host "|" -NoNewLine
    Out-Position $positions 6
    Write-Host "`n-----------"
    Out-Position $positions 7
    Write-Host "|" -NoNewLine
    Out-Position $positions 8
    Write-Host "|" -NoNewLine
    Out-Position $positions 9
    Write-Host "`n"
}


function Out-Position {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]
        $positions,
        [Parameter(Mandatory)]
        [int]
        $position
    )

    if ($positions[$position] -eq "X") {
        Write-Host " X " -NoNewLine -ForegroundColor "Cyan"
    }
    elseif ($positions[$position] -eq "O") {
        Write-Host " O " -NoNewLine -ForegroundColor "Yellow"
    }
    else {
        Write-Host " $($positions[$position]) " -NoNewLine -ForegroundColor "DarkGray"
    }
}


function Get-GameContinue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [WinCondition[]]
        $winConditions,
        [Parameter(Mandatory)]
        [string[]]
        $positions,
        [Parameter(Mandatory)]
        [int]
        $playerInput
    )

    foreach ($condition in $winConditions) {
        if ($condition.Matches -contains $playerInput) {
            if ($positions[$condition.Matches[0]] -eq $positions[$condition.Matches[1]] `
            -and $positions[$condition.Matches[1]] -eq $positions[$condition.Matches[2]]) {
                return $false
            }
        }
    }

    return $true
}


function Update-WinConditions {
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory)]
        [WinCondition[]]
        $winConditions,
        [Parameter(Mandatory)]
        [Player]
        $player,
        [Parameter(Mandatory)]
        [int]
        $playerInput
    )

    foreach ($condition in $winConditions) {
        if ($condition.Matches -contains $playerInput) {
            if ($player.Type -match "User") {
                $condition.UserPositions += $playerInput
                
                if ($condition.ComputerPositions.Length -ne 0) {
                    $condition.Status = "Blocked"
                }
                else {
                    $condition.Status = "Blockable"
                }
            }
            else {
                $condition.ComputerPositions += $playerInput

                if ($condition.UserPositions.Length -ne 0) {
                    $condition.Status = "Blocked"
                }
                else {
                    $condition.Status = "Winnable"
                }
            }
        }
    }

    return $winConditions
}


function Get-ComputerMove {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Player]
        $computer,
        [Parameter(Mandatory)]
        [WinCondition[]]
        $winConditions,
        [Parameter(Mandatory)]
        [int]
        $movesMade,
        [Parameter(Mandatory)]
        [string[]]
        $positions,
        [Parameter()]
        [int]
        $firstPlayerInput
    )

    if ($movesMade -eq 0) {
        Write-Debug "First Move"
        $move = Get-Random -Minimum 1 -Maximum 10
    }
    elseif ($movesMade -eq 1) {
        $randomConditionIndex = 0..7 | Get-Random -Count 8

        :secondMove for ($i = 0; $i -lt $winConditions.Count; $i++) {
            $condition = $winConditions[$randomConditionIndex[$i]]
            if ($condition.Matches -contains $playerInput) {
                $randomMatchPositionIndex = 0..2 | Get-Random -Count 3
                for ($j = 0; $j -lt $condition.Matches.Length; $j++) {
                    if ($condition.Matches[$randomMatchPositionIndex[$j]] -ne $playerInput) {
                        Write-Debug "Second Move"
                        $move = $condition.Matches[$randomMatchPositionIndex[$j]]

                        break secondMove
                    }
                }
            }
        }
    }
    else {
        $winningMove = @()
        $blockingMove = @()
        $progressMove = @()
        $randomMove = @()

        foreach ($condition in $winConditions) {
            # Find winning move
            if ($condition.ComputerPositions.Length -eq 2 -and $condition.Status -eq "Winnable") {
                foreach ($possibleMatch in $condition.Matches) {
                    if ($condition.ComputerPositions -notcontains $possibleMatch) {
                        $winningMove += $possibleMatch
                    }
                }
            }

            # Fine move to block user from winning
            if ($condition.UserPositions.Length -eq 2 -and $condition.Status -ne "Blocked") {
                foreach ($possibleMatch in $condition.Matches) {
                    if ($condition.UserPositions -notcontains $possibleMatch) {
                        $blockingMove += $possibleMatch
                    }
                }
            }

            # Find move to progress towards winning
            if ($condition.ComputerPositions.Length -eq 1 -and $condition.Status -ne "Blocked") {
                $randomMatchPositionIndex = 0..2 | Get-Random -Count 3
                for ($i = 0; $i -lt $condition.Matches.Length; $i++) {
                    if ($condition.Matches[$randomMatchPositionIndex[$i]] -ne $condition.ComputerPositions[0]) {
                        $progressMove += $condition.Matches[$randomMatchPositionIndex[$i]]
                    }
                }
            }

            # Find random available move
            $randomMoveIndex = 1..9 | Get-Random -Count 9     
            
            foreach ($num in $randomMoveIndex) {
                if ($positions[$num] -ne "X" -and $positions[$num] -ne "O") {
                    $randomMove += $positions[$num]
                }
            }
        }
    }

    if ($null -eq $move) {
        if ($winningMove.Length -ne 0) {
            Write-Debug "Winning Move"
            $move = $winningMove[0]
        }
        elseif ($blockingMove.Length -ne 0) {
            Write-Debug "Blocking Move"
            $move = $blockingMove[0]
        }
        elseif ($progressMove.Length -ne 0) {
            Write-Debug "Progress Move"
            $move = $progressMove[0]
        }
        else {
            Write-Debug "Random Move"
            $move = $randomMove[0]
        }
    }

    Write-Host "Computer chose $move" -ForegroundColor $computer.Color
    return $move
}


# $DebugPreference = "Continue"


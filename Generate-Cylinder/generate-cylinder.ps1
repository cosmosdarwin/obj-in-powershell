$FilePath = "rcc_20.obj"

$N = 20 # Number of vertices to compute to approximate circular ring
$R = 2 # Radius of the base
$H = 4 # Height between the bases

"# Right circular cylinder with radius $R, height $H, and $N vertices" | Out-File -FilePath $FilePath -Encoding ascii

# Vertices

1..($N) | ForEach {
    $A = $_ / $N * [Math]::Pi * 2 # Cumulative angle in radians, from 0 -> 2Pi
    $X = [Math]::Round([Math]::Cos($A) * $R , 3)
    $Z = [Math]::Round([Math]::Sin($A) * $R , 3)
    "v $X 0 $Z" | Add-Content $FilePath # Lower ring vertices
    "v $X $H $Z" | Add-Content $FilePath # Upper ring vertices
}

# Cylinder bases

$UpperBase = ""
$LowerBase = ""
1..(2 * $N) | ForEach {
    If ($_ % 2 -Eq 0) { # Even index vertices are upper ring
        $UpperBase = "$_ " + $UpperBase
    }
    Else { # Odds are lower ring
        $LowerBase = $LowerBase + "$_ "
    }
}
"f $UpperBase" | Add-Content $FilePath
"f $LowerBase" | Add-Content $FilePath

# Cylinder side walls

1..(2 * $N - 3) | ForEach {
    If ($_ % 2 -Eq 1) { # Generalize from 1 -> 2 -> 4 -> 3 base case, odds only
        $v1 = $_
        $v2 = $_ + 1
        $v3 = $_ + 3
        $v4 = $_ + 2
        "f $v1 $v2 $v3 $v4" | Add-Content $FilePath
    }
}

# Close it up!
"f -2 -1 2 1" | Add-Content $FilePath
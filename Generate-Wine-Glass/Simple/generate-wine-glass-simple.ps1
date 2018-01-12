$FilePath = "wine-glass-simple.obj"

$N_h = 100 # Level of detail along H (height) axis
$N_r = 20 # Level of detail along R (radial) axis

"# Crate & Barrel wine glass" | Out-File -FilePath $FilePath -Encoding ascii
"# Radial symmetry .obj generator in PowerShell" | Add-Content $FilePath
"# @cosmosdarwin on GitHub/Twitter, 2018" | Add-Content $FilePath

Function Measure-PointOnGuideCircle {
    Param (
        $CircleCenter, $CircleRadius, $H, [Switch]$Lower
    )
    $dH = [Math]::Round($CircleCenter[0] - $H, 3)
    $dR = [Math]::Round([Math]::sqrt([Math]::Pow($CircleRadius, 2) - [Math]::Pow($dH, 2)), 3)
    If ($Lower) {
        $CircleCenter[1] - $dR # Use "lower" edge of circle
    }
    Else {
        $CircleCenter[1] + $dR # Use "upper" edge of circle
    }
}

Function Add-Ring {
    Param (
        [String]$FilePath, [Int]$N, $H, $R, [Switch]$First
    )
    # Vertices of the ring
    1..($N) | ForEach {
        $A = $_ / $N * 2 * [Math]::Pi
        $X = [Math]::Round([Math]::Cos($A) * $R, 3)
        $Z = [Math]::Round([Math]::Sin($A) * $R, 3)
        "v $X $H $Z" | Add-Content $FilePath
    }

    # Connect to prior ring with quadrilateral sidewalls
    -$N..-2 | ForEach {
        $v1 = $_
        $v2 = $_ + 1
        $v3 = $_ + 1 -$N
        $v4 = $_ - $N
        "f $v1 $v2 $v3 $v4" | Add-Content $FilePath
    }
    "f -1 $(-$N) $(-2*$N) $(-$N-1)" | Add-Content $FilePath # Last quadrilateral closes ring
}

$GlassProfile = @() # List of (h, r) coordinates to form the profile of the wine glass

$GlassProfile += ,@(0, 0) # Start at origin

# Create the piecewise profile curve, starting "up" the outside from H = [0, 10]
0..$N_h | ForEach {
    $H = ($_ / $N_h) * 10.0
    If     (($H -Ge 0.0) -And ($H -Le  0.2)) { $R = Measure-PointOnGuideCircle -CircleCenter @(0.1, 1.5) -CircleRadius 0.1 -H $H }
    ElseIf (($H -Ge 0.2) -And ($H -Le  1.5)) { $R = Measure-PointOnGuideCircle -CircleCenter @(1.5, 1.4) -CircleRadius 1.3 -H $H -Lower }
    ElseIf (($H -Ge 3.8) -And ($H -Le  5.0)) { $R = Measure-PointOnGuideCircle -CircleCenter @(3.7, 2.0) -CircleRadius 1.9 -H $H -Lower }
    ElseIf (($H -Ge 6.1) -And ($H -Le  7.5)) { $R = Measure-PointOnGuideCircle -CircleCenter @(7.2, 0.0) -CircleRadius 1.9 -H $H }
    ElseIf (($H -Ge 9.9) -And ($H -Le 10.0)) { $R = Measure-PointOnGuideCircle -CircleCenter @(9.9, 1.3) -CircleRadius 0.1 -H $H }
    Else { Return } # Nothing to add, either straight segment or outside domain
    $GlassProfile += ,@($H, $R)
}

# Continue back "down" the inside from H = [10, 0]
$N_h..0 | ForEach {
    $H = ($_ / $N_h) * 10.0
    If     (($H -Ge 9.9) -And ($H -Le 10.0)) { $R = Measure-PointOnGuideCircle -CircleCenter @(9.9, 1.3) -CircleRadius 0.1 -H $H -Lower }
    ElseIf (($H -Ge 5.5) -And ($H -Le  7.5)) { $R = Measure-PointOnGuideCircle -CircleCenter @(7.2, 0.0) -CircleRadius 1.7 -H $H }
    Else { Return } # Nothing to add, either straight segment or outside domain
    $GlassProfile += ,@($H, $R)
}

$GlassProfile | ForEach {
    Add-Ring -FilePath $FilePath -N $N_r -H $_[0] -R $_[1]
}
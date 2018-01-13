$FilePath = "wine-glass-with-shading.obj"

$N_h = 200 # Level of detail along H (height) axis
$N_r = 40 # Level of detail along R (radial) axis


$outbuffer = @()
$outbuffer += "# Crate & Barrel wine glass" 
$outbuffer += "# Radial symmetry .obj generator in PowerShell"
$outbuffer += "# @cosmosdarwin on GitHub/Twitter, 2018" 

$outbuffer += "mtllib wine-glass-materials.mtl"

Function ConvertTo-UnitVector {
    <#
      .SYNOPSIS Take $InputVector and scale it to $OutputMagnitude, or 1.0 if unspecified
      .PARAMETER InputVector Array (x, y) of two components
      .PARAMETER OutputMagnitude Scalar (OPTIONAL)
    #>

    Param (
        $InputVector, $OutputMagnitude = 1.0
    )

    # Calculate magnitude of InputVector
    $Magnitude = [Math]::Round([Math]::sqrt([Math]::Pow($InputVector[0], 2) + [Math]::Pow($InputVector[1], 2)), 3)
    If ($Magnitude -Gt 0) {
        # Divide by magnitude to get unit vector
        $UnitVector = @($($InputVector[0]/$Magnitude), $($InputVector[1]/$Magnitude))
        # Scale (if requested) and return
        @($($UnitVector[0] * $OutputMagnitude), $($UnitVector[1] * $OutputMagnitude))
    }
    Else {
        @(0, 0) # Don't divide by zero
    }
}

Function Measure-PointOnGuideCircle {
    <#
      .SYNOPSIS In the h-r plane (the "profile"), evaluate the point $H along the upper (default) or -Lower ring of a guide circle of specified center and radius
      .PARAMETER CircleCenter The coordinates (h, r) of the center of the guide circle
      .PARAMETER CircleRadius The radius of the guide circle
      .PARAMETER Lower Flag whether to use the "lower" edge of the guide circle (OPTIONAL FLAG)
      .PARAMETER Inside Flag whether the radial component of the normal should be reversed (OPTIONAL FLAG)
    #>

    Param (
        $CircleCenter, $CircleRadius, $H, [Switch]$Lower, [Switch]$Inside
    )

    $dH = [Math]::Round($CircleCenter[0] - $H, 3)
    $dR = [Math]::Round([Math]::sqrt([Math]::Pow($CircleRadius, 2) - [Math]::Pow($dH, 2)), 3)

    # Point (h, r) itself
    If ($Lower) {
        $R = $CircleCenter[1] - $dR # In h-r plane, use "lower" edge of circle
    }
    Else {
        $R = $CircleCenter[1] + $dR # In h-r plane, use "upper" edge of circle
    }
    $ProfilePlanePoint = @($H, $R)

    # Normal (dH, dR) to the curve
    If (!$Lower) {
        $dH = -$dH
    }
    If ($Inside) {
        $dH = -$dH
        $dR = -$dR
    }
    $ProfilePlaneNormal = ConvertTo-UnitVector -InputVector @($dH, $dR)

    @($ProfilePlanePoint, $ProfilePlaneNormal) # Return
}

Function Add-RingToCylindroid {
    <#
      .SYNOPSIS Add one ring to the cylindroid and connect it to the prior one with quadrilateral sidewalls
      .PARAMETER First Whether this is the first ring, so no sidewalls (OPTIONAL FLAG)
      .PARAMETER FilePath Path to existing .obj file to modify
      .PARAMETER N_r Number of vertices to compute to approximate circular ring
      .PARAMETER ProfilePointAndNormal Coordinates (h, r) of point in the h-r "profile" plane, and normal (dH, dR) to the profile curve at the point
    #>

    Param (
        [Switch]$First, [String]$FilePath, [Int]$N_r, $ProfilePointAndNormal
    )

    # Point
    $H = $ProfilePointAndNormal[0][0]
    $R = $ProfilePointAndNormal[0][1]
    # Normal
    $dH = $ProfilePointAndNormal[1][0]
    $dR = $ProfilePointAndNormal[1][1]

    # Vertices of the ring
    1..$N_r | ForEach {
        $A = $_ / $N_r * 2 * [Math]::Pi
        $X = [Math]::Round([Math]::Cos($A) * $R, 3)
        $Z = [Math]::Round([Math]::Sin($A) * $R, 3)
        "v $X $H $Z" 
        # Scale the radial plane (X, Z) components to the profile plane dR component
        $RadialPlaneNormal = ConvertTo-UnitVector -InputVector @($X, $Z) -OutputMagnitude $dR
        "vn $($RadialPlaneNormal[0]) $dH $($RadialPlaneNormal[1])" 
    }

    # Unless this is the first ring, connect to prior ring with quadrilateral sidewalls
    If (!$First) {
        -$N_r..-2 | ForEach {
            $v1 = $_
            $v2 = $_ + 1
            $v3 = $_ + 1 -$N_r
            $v4 = $_ - $N_r
            "f $v1//$v1 $v2//$v2 $v3//$v3 $v4//$v4"
        }
        "f -1//-1 $(-$N_r)//$(-$N_r) $(-2*$N_r)//$(-2*$N_r) $(-$N_r-1)//$(-$N_r-1)" # Last quadrilateral closes ring
    }
}

#######################
### Object 1: Glass ###
#######################

$GlassProfile = @() # List of points (h, r) along the profile, and normal (dH, dR) to the profile curve at each point

# Create the piecewise profile curve, starting "up" the inside from H = [0, 10]
0..$N_h | ForEach {
    $H = ($_ / $N_h) * 10.00
    If     (($H -Ge 9.95) -And ($H -Le 10.00)) { $GlassProfile += ,@(Measure-PointOnGuideCircle -CircleCenter @(9.95, 1.30) -CircleRadius 0.05 -H $H -Inside -Lower) }
    ElseIf (($H -Ge 5.40) -And ($H -Le  7.50)) { $GlassProfile += ,@(Measure-PointOnGuideCircle -CircleCenter @(7.20, 0.00) -CircleRadius 1.80 -H $H -Inside) }
}

# Continue back "down" the outside from H = [10, 0]
$N_h..0 | ForEach {
    $H = ($_ / $N_h) * 10.00
    If     (($H -Ge 0.00) -And ($H -Le  0.10)) { $GlassProfile += ,@(Measure-PointOnGuideCircle -CircleCenter @(0.05, 1.50) -CircleRadius 0.05 -H $H) }
    ElseIf (($H -Ge 0.10) -And ($H -Le  1.40)) { $GlassProfile += ,@(Measure-PointOnGuideCircle -CircleCenter @(1.40, 1.40) -CircleRadius 1.30 -H $H -Lower) }
    ElseIf (($H -Ge 3.80) -And ($H -Le  5.00)) { $GlassProfile += ,@(Measure-PointOnGuideCircle -CircleCenter @(3.70, 2.00) -CircleRadius 1.90 -H $H -Lower) }
    ElseIf (($H -Ge 6.10) -And ($H -Le  7.50)) { $GlassProfile += ,@(Measure-PointOnGuideCircle -CircleCenter @(7.20, 0.00) -CircleRadius 1.90 -H $H) }
    ElseIf (($H -Ge 9.95) -And ($H -Le 10.00)) { $GlassProfile += ,@(Measure-PointOnGuideCircle -CircleCenter @(9.95, 1.30) -CircleRadius 0.05 -H $H) }
}

$outbuffer += "usemtl glass"

# Create cylindroid ring-by-ring by iterating through points on the profile curve
$outbuffer += $GlassProfile | ForEach {
    If ([array]::indexof($GlassProfile, $_) -Eq 0) { # First
        Add-RingToCylindroid -FilePath $FilePath -N $N_r -ProfilePointAndNormal $_ -First
    }
    Else {
        Add-RingToCylindroid -FilePath $FilePath -N $N_r -ProfilePointAndNormal $_
    }
}

$outbuffer += "f $(-$N_r..-1)" # Add base to close the cylindroid

######################
### Object 2: Wine ###
######################

$WineProfile = @() # List of points (h, r) along the profile, and normal (dH, dR) to the profile curve at each point

# Create the piecewise profile curve, starting "up" from H = [0, 10]
0..$N_h | ForEach {
    $H = ($_ / $N_h) * 10.00
    If (($H -Ge 5.40) -And ($H -Le  7.00)) { $WineProfile += ,@(Measure-PointOnGuideCircle -CircleCenter @(7.20, 0.00) -CircleRadius 1.80 -H $H) }
}

$outbuffer += "usemtl wine"

# Create cylindroid ring-by-ring by iterating through points on the profile curve
$outbuffer += $WineProfile | ForEach {
    If ([array]::indexof($WineProfile, $_) -Eq 0) { # First
        Add-RingToCylindroid -FilePath $FilePath -N $N_r -ProfilePointAndNormal $_ -First
    }
    Else {
        Add-RingToCylindroid -FilePath $FilePath -N $N_r -ProfilePointAndNormal $_
    }
}

$outbuffer += "f $(-$N_r..-1)" # Add base to close the cylindroid

$outbuffer | Out-File -FilePath $FilePath -Encoding ascii

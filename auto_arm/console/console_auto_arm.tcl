 #!/sw/bin/wish
# ----------------------------------------------------------------------------------------
# -- HEIG-VD /////////////////////////////////////////////////////////////////////////////
# -- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
# -- School of Business and Engineering in Canton de Vaud
# ----------------------------------------------------------------------------------------
# -- REDS Institute //////////////////////////////////////////////////////////////////////
# -- Reconfigurable Embedded Digital Systems
# ----------------------------------------------------------------------------------------
# --
# -- File                 : console_auto_arm.tcl
# -- Author               : Thomas Rieder
# -- Date                 : 21 décembre 2023
# --
# -- Context              : Laboratoires de SYL
# --
# ----------------------------------------------------------------------------------------
# -- Description :
# --   Console virtuelle permettant la simulation d'un bras de triage automatique
# --
# ----------------------------------------------------------------------------------------
# -- Modifications :
# -- Ver   Date        Engineer   Comments
# --
# ----------------------------------------------------------------------------------------

package require Tk

# Set global variables
set consoleInfo(version) 1.0.0
set consoleInfo(title) "SYL Bras de triage"; # Title that will be display in title bar
set consoleInfo(filename) "console_auto_arm"; # Filename without the filetype

set redsToolsPath /opt/tools_reds
set Env linux
set debugMode FALSE; # Display debug info
set sigImgFile "./REDS_console_sigImg.gif"

# Load resources
if { [catch {source $redsToolsPath/TCL_TK/Graphical_Elements.tcl} msg1] } {
  puts "Set path for Windows environment"
  set redsToolsPath c:/EDA/tools_reds
  set Env windows
  if { [catch {source $redsToolsPath/TCL_TK/Graphical_Elements.tcl} msg2] } {   
    puts "Cannot load Graphical Elements!"
    }
}

source $redsToolsPath/TCL_TK/StdProc.tcl

# ----------------------------------------------------------------------------------------
# -- Fonctions appelees par Logisim  /////////////////////////////////////////////////////
# ----------------------------------------------------------------------------------------

# --| ENABLELOGISIM |---------------------------------------------------------------------
# --   Set fonts and addresses
# ----------------------------------------------------------------------------------------
proc enableLogisim {enabled} {
  global logisimEnabled
  #TRUE or FALSE
  set logisimEnabled $enabled
  echo "Logisim enabled: $logisimEnabled"
}

# --| LOGISIMFORCE |----------------------------------------------------------------------
# --   Dans Logisim, Lorsqu'un "tick" est genere, cette fonction est appele
# ----------------------------------------------------------------------------------------
proc logisimForce {} {
  SetOutputs
  # RunDisplay
}

# --| LOGISIMEXAMINE |--------------------------------------------------------------------
# --   Dans Logisim, Lorsqu'une valeur change d'etat a l'entree de la console, 
# --   cette fonction est appelee.
# ----------------------------------------------------------------------------------------
proc logisimExamine {} {
  ReadInputs
}

# ----------------------------------------------------------------------------------------
# -- Fonctions de gestion de la console //////////////////////////////////////////////////
# ----------------------------------------------------------------------------------------

# --| SETVARIABLES |----------------------------------------------------------------------
# --  Set fonts and addresses
# ----------------------------------------------------------------------------------------
proc SetVariables {} {
  # Global variables, see below
  global fnt speed runningMode reset

  # Speeds
  if {$runningMode == "Simulation"} {
    set speed(Refresh) 500; # Time [ms] between run steps (target mode)
  } else {
    set speed(Refresh) 500;
  }

  # Fonts
  font create fnt{3} -family {MS Sans Serif} -weight bold -size 8; puts ""
  font create fnt{4} -family {MS Sans Serif} -weight normal -size 8; puts ""
  font create fnt{5} -family {Courier New} -weight normal -size 8; puts ""

  set reset 1

  
}

set reset 0

proc ResetVariables {} {

  global num_boites newBoxX1 newBoxY1 newBoxX2 newBoxY2 codeColor
  global scan_i throw_i move_i dest_red_i dest_blue_i dest_init_i drop_i pos_bras sysclk_i direction blueCount redCount
  global reset

  # force -freeze /console_sim/rst\_o 1

  if {$num_boites == 1} {
    .top.can delete boite_curr
  }

  set num_boites 0

  set newBoxX1 305
  set newBoxY1 115

  set newBoxX2 335
  set newBoxY2 145

  array set codeColor {
      0 1
      1 1
  }

  set scan_i 0
  set throw_i 0
  set move_i 0
  set dest_red_i 0
  set dest_blue_i 0
  set dest_init_i 0
  set drop_i 0
  set pos_bras 6
  set sysclk_i 0
  set direction -1
  set blueCount 0
  set redCount 0
  set reset 1

  .top.can.txtBlueCount configure -text $blueCount
  .top.can.txtRedCount configure -text $redCount

  # SetOutputs
  RunDisplay

}

# --| CLOSECONSOLE |----------------------------------------------------------------------
# --  Prepare la fermeture de la console en detruisant certains des objets crees. Ceci
# --  permet la reouverture de la console, mais evite egalement la polution de la memoire
# --  en detruisant les objets inutilises.
# --  Cette procedure est appelee a la fermeture de la fenetre ainsi que par la
# --  procedure "QuitConsole{}".
# ----------------------------------------------------------------------------------------
proc CloseConsole {} {
  global fnt runningMode AdrReset runText

  # Stop simulation if it is running
  if {$runText == "Stop"} {
    set runText Run
  }

  # Destruction des objets du top
  foreach w [winfo children .top] {
    destroy $w
  }

  # Desctruction du top
  destroy .top

  # Suppression des polices
  font delete fnt{3}
  font delete fnt{4}

  if {$runningMode == "Simulation"} {
    # Delete all signal on wave view
    #delete wave *

  } else {
    # Reset the line driver OE of the board
    EcrireUSB $AdrReset 0

    # Exit application
    exit
  }

  # Free variable
  unset runText
  unset runningMode
}


# --| QuitConsole |-----------------------------------------------------------------------
# --  Appel la fonction de fermeture de la console, puis quitte.
# ----------------------------------------------------------------------------------------
proc QuitConsole {} {
  CloseConsole; # Clean before closing
  exit
}


# --| CHECKRUNNINGMODE |-------------------------------------------------------------------------
# --  Check if the console was started from simulation (Simulation running mode) or
# --  in standalone (Target running mode).
# ----------------------------------------------------------------------------------------
proc CheckRunningMode {} {
  # Global variables:
  #   - Path to the resources
  #   - Current running mode
  global strResourcePath runningMode redsToolsPath consoleInfo Env

  # Directory where the USB2 drivers are installed
  set InstallDir "$redsToolsPath/lib/usb2/"
  if {$Env == "linux" } {
    set libName "libredsusb.so"
  } else {
    set libName "GestionUSB2.dll"
  }

  # No error by default
  set isErr 0

  # Check for standalone run (meaning it has not been launched from QuestaSim)
  if {[wm title .] == $consoleInfo(filename)} {
    wm withdraw .
  }

  # Check the running mode -> Simulation or Target
  catch {restart -f} err1
  if {$err1 != "invalid command name \"restart\""} {
    set runningMode "Simulation"
  } else {
    set runningMode "Target"
    # Test if the DLL "GestionUSB2" is installed
    catch {load $InstallDir$libName} err2
    if {$err2 != "" } {
      # Error --> try in local folder
      catch {load $libName} err3
      if {$err3 != "" } {
        # Installation error
        set msgErr "$libName n'est pas installee : $err2 - $err3"
        set isErr  1
      } else {
        set InstallDir .
      }
    }
    if {$isErr == 0} {
      UsbSetDevice 08ee 4002
    }
  }

  # affichage de l'erreur s'il a lieu
  if {$isErr == 1} {
      tk_messageBox -icon error -type ok -title error -message $msgErr
      exit  ; # quitte l'application
  }

}

set num_boites 0

set newBoxX1 305
set newBoxY1 115

set newBoxX2 335
set newBoxY2 145

array set codeColor {
    0 1
    1 1
}

# --| create_boite |-------------------------------------------------------------
# procédure pour créer une nouvelle boite sur le tapis 1
# -------------------------------------------------------------------------------
proc create_boite {type} {
    global num_boites codeColor pos_bras newBoxX1 newBoxY1 newBoxX2 newBoxY2

    #set y_boite [lindex [.top.can coords boite_tapis1] 1]
    ## vérification au préalable qu'on ne va pas superposer la nouvelle boite
    ## avec une autre
    if {$num_boites == 0 && $pos_bras == 6} {

        .top.logInfo configure -text "New Box" -fg #009900
            # .top.can create rectangle 300 115 330 130 -fill red -width 0 -tag boite$type
        # RED
        if {$type == 1} {
            .top.can create rectangle $newBoxX1 $newBoxY1 $newBoxX2 $newBoxY2 -fill red -width 1 -tag boite_curr
            set codeColor(0) 1
            set codeColor(1) 0

        # BLUE
        } elseif {$type == 2} {
            .top.can create rectangle $newBoxX1 $newBoxY1 $newBoxX2 $newBoxY2 -fill blue -width 1 -tag boite_curr
            set codeColor(0) 0
            set codeColor(1) 1

        # UNKNOWN
        } elseif {$type == 3} {
            .top.can create rectangle $newBoxX1 $newBoxY1 $newBoxX2 $newBoxY2 -fill yellow -width 1 -tag boite_curr
            set codeColor(0) 0
            set codeColor(1) 0
        }

        set num_boites 1
    } else {
      .top.logInfo configure -text "Arm not in postion" -fg #990000
    }
}

# --| CREATEMAINWINDOW |------------------------------------------------------------------
# --  Creation de la fenetre principale
# ----------------------------------------------------------------------------------------
proc CreateMainWindow {} {
  global consoleInfo fnt{3} runningMode images debugLabel runText
  global continuMode sigImgFile
  global pos_boite_ang newBoxX1 newBoxY1 newBoxX2 newBoxY2

  # creation de la fenetre principale
  toplevel .top -class toplevel

  # Call "CloseConsole" when Top is closed
  wm protocol .top WM_DELETE_WINDOW CloseConsole

  set Win_Width  750
  set Win_Height 450

  set x0 200
  set y0 200

  wm geometry .top $Win_Width\x$Win_Height+$x0+$y0

  wm resizable  .top 0 0
  wm title .top "$consoleInfo(title) $consoleInfo(version) - $runningMode mode"

  # Create menu
  menu .top.menu -tearoff 0
  set file .top.menu.file
  set run .top.menu.run
  menu $file -tearoff 0
  menu $run -tearoff 0
  .top.menu add cascade -label "Fichier" -menu $file -underline 0
  .top.menu add cascade -label "Run" -menu $run -underline 0


  # "Run" menu
  $run add command -label "Run" -command StartStopManager -accelerator "Ctrl-R" \
                   -underline 0
  $run add command -label "Stop" -command StartStopManager -accelerator "Ctrl-S" \
                   -underline 0 -state disabled
  $run add separator
  $run add checkbutton -label "Run continu" -variable continuMode

  # Some bindings for menu accelerator
  bind .top <Control-r> {RunStep}
  bind .top <Control-R> {RunStep}


  # "File" menu
  $file add command -label "Fermer" -command CloseConsole -accelerator "Ctrl-W" \
                    -underline 0
  $file add separator
  $file add command -label "Quitter" -command QuitConsole -accelerator "Ctrl-Q" \
                    -underline 0

  # Some bindings for menu accelerator
  bind .top <Control-w> {CloseConsole}
  bind .top <Control-W> {CloseConsole}
  bind .top <Control-q> {QuitConsole}
  bind .top <Control-Q> {QuitConsole}




    # Configure menubar
    .top configure -menu .top.menu


    ### creation du canvas dans lequel on met le système ###
    canvas .top.can -width 700 -height 300 
    place .top.can -x 0 -y 0

    set tapisPosX [expr {$newBoxX1 - 20}]
    set tapisPosY [expr {$newBoxY1 - 20}]
    set tapisWidth [expr {$newBoxX2 + 20}]
    set tapisHeight [expr {$newBoxY2 + 20}]

    set cbPosX [expr {[lindex $pos_boite_ang 0 0] + $newBoxX1 - 10}]
    set cbPosY [expr {[lindex $pos_boite_ang 0 1] + $newBoxY1 - 10}]
    set cbWidth [expr {[lindex $pos_boite_ang 0 0] + $newBoxX2 + 10}]
    set cbHeight [expr {[lindex $pos_boite_ang 0 1] + $newBoxY2 + 10}]

    set crPosX [expr {[lindex $pos_boite_ang 12 0] + $newBoxX1 - 10}]
    set crPosY [expr {[lindex $pos_boite_ang 12 1] + $newBoxY1 - 10}]
    set crWidth [expr {[lindex $pos_boite_ang 12 0] + $newBoxX2 + 10}]
    set crHeight [expr {[lindex $pos_boite_ang 12 1] + $newBoxY2 + 10}]

    set brasP0X 300
    set brasP0Y 130

    set brasP1X 340
    set brasP1Y 130

    set brasP2X 340
    set brasP2Y 280

    set brasP3X 300
    set brasP3Y 280

    set footX1 [expr {$brasP3X - 20}]
    set footY1 [expr {$brasP3Y - 5}]
    set footX2 [expr {$brasP2X + 20}]
    set footY2 [expr {$brasP2Y + 85}]

    ### creation d'une led pour le scan ###
    createLed .top.can.scanLed [expr {$tapisWidth + 30}] [expr {$tapisPosY - 40}] 1 horizontal 1; 
    label .top.can.txtScanLed -text "scan" -fg #000000 -font "fnt4"
    place .top.can.txtScanLed -x [expr {$tapisWidth + 27}] -y [expr {$tapisPosY - 10}]

    ### creation du trap ###
    .top.can create rectangle $tapisPosX $tapisPosY $tapisWidth $tapisHeight -fill "darkgray" -width 2 -tag trap

    ### creation du container bleu ###
    .top.can create rectangle $cbPosX $cbPosY $cbWidth $cbHeight -fill blue -width 2 -tag cblue

    ### creation du container rouge ###
    .top.can create rectangle $crPosX $crPosY $crWidth $crHeight -fill red -width 2 -tag cblue

    ### creation du pieds du Bras ###
    .top.can create oval $footX1 $footY1 $footX2 $footY2 -fill white -width 2 -tag arm_foot
    ### creation du Bras ###
    .top.can create poly $brasP0X $brasP0Y $brasP1X $brasP1Y $brasP2X $brasP2Y $brasP3X $brasP3Y -fill white -outline black -tag arm

    ### creation des boutons d'ajout d'une boite sur le tapis #### 
    button .top.boiter -text "boite Rouge" -command {create_boite 1}
    place .top.boiter -x 200 -y 415
    button .top.boiteb -text "boite Bleue" -command {create_boite 2}
    place .top.boiteb -x 300 -y 415
    button .top.boitei -text "boite Inconnue" -command {create_boite 3}
    place .top.boitei -x 400 -y 415

    label .top.log -text "INFO:" -fg #009900 -bg #BBBBBB -font "fnt4"
    place .top.log -x 200 -y 380
    label .top.logInfo -text "..." -fg #009900 -bg #BBBBBB -font "fnt4"
    place .top.logInfo -x 250 -y 380

    label .top.can.txtBlueCount -text "0" -fg #ffffff -bg #0000FF -font "fnt4"
    place .top.can.txtBlueCount -x [expr {$cbWidth - 20}] -y [expr {$cbHeight + 10}]
    label .top.can.txtRedCount -text "0" -fg #ffffff -bg #FF0000 -font "fnt4"
    place .top.can.txtRedCount -x [expr {$crWidth - 20}] -y [expr {$crHeight + 10}]


    # .top itemconfig loginfo -text "ALED"

    set column3 670

    # Create spinbox for "Continu" mode
    checkbutton .top.continuMode -text "Continu" -font fnt{3} -variable continuMode
    place .top.continuMode -x $column3 -y 10

    button .top.run -text "Run" -command {StartStopManager} -font fnt{3} -textvariable runText
    place .top.run -x $column3 -y 30 -height 22 -width 70

    button .top.restart -text "RESET" -command {RestartSim} -font fnt{3}
    place .top.restart -x $column3 -y 55 -height 22 -width 70

    # Creation du bouton "Quitter"
    button .top.exit -text "Quitter" -command QuitConsole -font fnt{3}
    place .top.exit  -x $column3 -y 100 -height 22 -width 70


}


# --| ShowSignalLabels |------------------------------------------------------------------
# --  Show a side window with the image $images(sigImgLabels)"
# ----------------------------------------------------------------------------------------
proc ShowSignalLabels {} {
  global images sigImgFile windowOpen

  proc CloseSignalLabels {} {
    global windowOpen
    set windowOpen(SignalLabels) FALSE;
    wm withdraw .info;
    destroy .info
  }

  if {$windowOpen(SignalLabels) == FALSE} {
    # Create and arrange the dialog contents.
    toplevel .info

    set windowOpen(SignalLabels) TRUE
    wm protocol .info WM_DELETE_WINDOW {CloseSignalLabels}

    set screenx [winfo screenwidth .top]
    set screeny [winfo screenheight .top]
    set x [expr [winfo x .top] + [winfo width .top] + 10]
    set y [expr [winfo y .top]]
    set width 478
    set height 259

    if {[expr $x + $width] > [expr $screenx]} {
      set x [expr $x - [winfo width .top] - $width - 10]
    }

    # Canvas for the boat image
    canvas .info.cimg -height $height -width $width
    place .info.cimg -x 0 -y 0

    set images(sigImgLabels) [image create photo -file "$sigImgFile"]; puts ""
    .info.cimg create image [expr $width/2] [expr $height/2] -image $images(sigImgLabels)

    wm geometry  .info [expr $width]x[expr $height]+$x+$y
    wm resizable  .info 0 0
    wm title     .info "D\E9signation des signaux"
    wm deiconify .info
  }
}


# --| ShowAbout |-------------------------------------------------------------------------
# --  Show the "About" window
# ----------------------------------------------------------------------------------------
proc ShowAbout {} {
    global infoLabel windowOpen consoleInfo

  proc CloseAbout {} {
    global windowOpen
    set windowOpen(About) FALSE;
    wm withdraw .about;
    destroy .about

    wm attributes .top -disabled FALSE
    wm attributes .top -alpha 1.0
  }

  if {$windowOpen(About) == FALSE} {
    # Create and arrange the dialog contents.
    toplevel .about

    set windowOpen(About) TRUE
    wm protocol .about WM_DELETE_WINDOW {CloseAbout}

    # Disable top
    wm attributes .top -disabled TRUE
    wm attributes .top -alpha 0.8

    set width 250
    set height 200

    set x [expr [winfo x .top]+[winfo width .top]/2-$width/2]
    set y [expr [winfo y .top]+[winfo height .top]/2-$height/2]

    button .about.ok -text OK -command {CloseAbout}
    place .about.ok -x [expr $width/2] -y [expr $height-20] -width 70 -height 30 -anchor s

    set infoLabel "$consoleInfo(title) version $consoleInfo(version) \
                   \n\nAuteurs:\nJean-Pierre Miceli\nGilles Curchod \
                   \n\nREDS (c) 2005 - [clock format [clock seconds] -format %Y]"
    label .about.label -textvariable infoLabel -font fnt{5} -justify center
    place .about.label -x [expr $width/2] -y 20 -anchor n

    wm geometry  .about [expr $width]x[expr $height]+$x+$y
    wm title     .about "a propos"
    wm transient .about .top
    wm attributes .about -topmost; # On top fo all
    wm resizable  .about 0 0; # Cannot resize
    wm frame .about

  }
}


# --| dec2bin |---------------------------------------------------------------------------
# --  Transform a decimal value to a binary string. (Max 32-bits)
# --    - value:   The value to be converted
# --    - NbrBits: Number of bit of "value"
# ----------------------------------------------------------------------------------------
proc dec2bin {value {NbrBits 16}} {
    binary scan [binary format I $value] B32 str
    return [string range $str [expr 32-$NbrBits] 31]
}



# --| SetOutputs |------------------------------------------------------------------------
# --  Affectation des signaux
# ----------------------------------------------------------------------------------------
proc SetOutputs {} {
  global runningMode \
         debugLabel debugMode codeColor num_boites scan_i reset



  # Affectation des valeurs aux signaux respectifs
  if {$runningMode == "Simulation"} {
    
    force -freeze /console_sim/S0\_sti $num_boites

    if {$scan_i == 1} {
        force -freeze /console_sim/S1\_sti $codeColor(0)
        force -freeze /console_sim/S2\_sti $codeColor(1)
    } else {
        
        force -freeze /console_sim/S1\_sti 1
        force -freeze /console_sim/S2\_sti 1
    }

  }

  force -freeze /console_sim/rst\_o $reset

  set reset 0

  if {$debugMode == TRUE} {
    set debugLabel(1) "S:$switchesStates"
  }
}

set scan_i 0
set throw_i 0
set move_i 0
set dest_red_i 0
set dest_blue_i 0
set dest_init_i 0
set drop_i 0
set pos_bras 6
set sysclk_i 0

set direction -1

set blueCount 0
set redCount 0


# --| ReadInputs |------------------------------------------------------------------------
# --  Lecture des entrees
# ----------------------------------------------------------------------------------------
proc ReadInputs {} {
#   global runningMode \
#          AdrDataPinG41_48 \
#          debugLabel debugMode
    global scan_i throw_i move_i \
            dest_red_i dest_blue_i dest_init_i \
            drop_i boite_curr num_boites pos_bras direction blueCount codeColor sysclk_i

  # --------------------------------------------------------------------------------------
  # Lecture des valeurs des entrees
  # --------------------------------------------------------------------------------------
  set scan_i [examine /console_sim/L0\_obs]
  set throw_i [examine /console_sim/L1\_obs]
  set move_i [examine /console_sim/L2\_obs]
  set dest_red_i [examine /console_sim/L3\_obs]
  set dest_blue_i [examine /console_sim/L4\_obs]
  set dest_init_i [examine /console_sim/L5\_obs]
  set drop_i [examine /console_sim/L6\_obs]
  set sysclk_i [examine /console_sim/sysclk\_i]

  # --------------------------------------------------------------------------------------
  # Mise a jour des affichages
  # --------------------------------------------------------------------------------------

    if {$throw_i == 1 && $num_boites == 1} {
          if {$throw_i == 1} {
            .top.can itemconfigure trap -fill "black"
          }
        .top.can delete boite_curr
        set num_boites 0
    } else {
      .top.can itemconfigure trap -fill "darkgray"
    }

    if {$move_i == 1} {
        set direction -1
        if {$dest_red_i == 1 && $pos_bras < 11} {
            
            # incr $pos_bras
            set direction 1

        } elseif {$dest_blue_i == 1 && $pos_bras > 0} {
         
            # decr $pos_bras
            # incr $pos_bras -1
            set direction 0

        } elseif {$dest_init_i == 1} {
            if {$pos_bras < 6} {

                # incr $pos_bras
                set direction 1
            } elseif {$pos_bras > 6} {

                # incr $pos_bras -1
                set direction 0
            }
        }
    } else {

      set direction -1
    }

    

}

set og1_x 300
set og1_y 280

set og2_x 340
set og2_y 280

# 40: {-114 -96}
# 50: {-96 -115}
# 60: {-75 -130}
# 65: {-63 -136}
# 70: {-51 -141}
# 80: {-26 -148}
# 90: {0 -150}
# 100:{26 -148}
# 110:{51 -141}
# 115:{63 -136}
# 120:{75 -130}
# 130:{96 -115}
# 140:{114 -96}
set pos_arm_ang {
    {-114 -96}
    {-96 -115}
    {-75 -130}
    {-63 -136}
    {-51 -141}
    {-26 -148}
    {0 -150}
    {26 -148}
    {51 -141}
    {63 -136}
    {75 -130}
    {96 -115}
    {114 -96}
}


set pos_boite_ang {
    {-114 54}
    {-96 35}
    {-75 20}
    {-63 14}
    {-51 9}
    {-26 2}
    {0 0}
    {26 2}
    {51 9}
    {63 14}
    {75 20}
    {96 35}
    {114 54}
}

# --| RunDisplay |------------------------------------------------------------------------
# --  Son role est determiner lorsque le bouton "Run" est presse ou en continu si
# --  la console est utilise avec Logisim, Questasim ou en standalone.
# --  La commande "run" permet de declencher un "tick" dans Logisim.
# ----------------------------------------------------------------------------------------
proc RunDisplay {} {
    global logisimEnabled og1_x og1_y og2_x og2_y \
            pos_arm_ang pos_boite_ang pos_bras direction \
            newBoxX1 newBoxY1 newBoxX2 newBoxY2 redCount blueCount \
            num_boites drop_i codeColor sysclk_i throw_i scan_i

    if {$logisimEnabled == TRUE} {
        echo "Console running through Logisim..."
        run
    } else {
        runQuestaTarget
    }

    if {$scan_i == 1} {
      setLed .top.can.scanLed 0 ON
    } else {
      setLed .top.can.scanLed 0 OFF
    }
    
    if {$direction == 0} {
      incr pos_bras -1
    } elseif {$direction == 1} {
      incr pos_bras
    }

    ## Move bras
    # .top.can move boite_curr 1 0
    set coords [.top.can coords arm]
    set vx [lindex $pos_arm_ang $pos_bras 0]
    set vy [lindex $pos_arm_ang $pos_bras 1]

    set x1 [expr {$vx + $og1_x}]
    set y1 [expr {$vy + $og1_y}]

    set x2 [expr {$vx + $og2_x}]
    set y2 [expr {$vy + $og2_y}]

    .top.can coords arm [lreplace $coords 0 3 $x1 $y1 $x2 $y2]

    ## Move boite
    set coords [.top.can coords boite_curr]
    set vx [lindex $pos_boite_ang $pos_bras 0]
    set vy [lindex $pos_boite_ang $pos_bras 1]

    set x1 [expr {$vx + $newBoxX1}]
    set y1 [expr {$vy + $newBoxY1}]

    set x2 [expr {$vx + $newBoxX2}]
    set y2 [expr {$vy + $newBoxY2}]

    # .top.can move boite_curr $vx $vy
    .top.can coords boite_curr [lreplace $coords 0 3 $x1 $y1 $x2 $y2]

    # incr cpt_arm
    if {$drop_i == 1 && $sysclk_i == 1} {

      if {$num_boites == 0} {
      
        echo "Drop but no Box: ERROR"
        .top.logInfo configure -text "Drop but no Box" -fg #990000

      } else {

      
        # Drop the box no matter the position
        .top.can delete boite_curr
        set num_boites 0

          # Drop on Blue contener
        if {$pos_bras == 0} {
          if {$codeColor(0) == 0 && $codeColor(1) == 1} {
            echo "in Blue is Blue"
            incr blueCount
            .top.can.txtBlueCount configure -text $blueCount
            .top.logInfo configure -text "Good" -fg #009900
          } else {
            .top.logInfo configure -text "Bad Box" -fg #990000

          }
          # 
          # Drop on red contener
        } elseif {$pos_bras == 12} {
          if {$codeColor(0) == 1 && $codeColor(1) == 0} {
            echo "in RED is RED"
            incr redCount
            .top.can.txtRedCount configure -text $redCount
            .top.logInfo configure -text "Good" -fg #009900
          } else {
            .top.logInfo configure -text "Bad Box" -fg #990000

          }

          # Drop error (lost box)
        } else {
          echo "in Nothing: ERROR"
           .top.logInfo configure -text "Box Lost" -fg #990000

        }

      #   # No box on arm
      }
    }
}




# --| runQuestaTarget |-------------------------------------------------------------------
# --  Son role est de forcer les valeurs des entrees, de faire avancer le temps
# --  et enfin d'affecter les valeurs obtenues.
# --  Elle est appelee seulement si la console est utilise avec Questasim ou en
# --  standalone.
# ----------------------------------------------------------------------------------------
proc runQuestaTarget {} {
  global runningMode runText

  # Affectation des sorties
  SetOutputs

  # Avancement du temps
  if {$runningMode == "Simulation"} {
    run 100 ns
  } else {
    ## Target mode...
    after 1 {
        set continue 1
    }
    vwait continue
    update
    set continue 0
  }

  # Lecture des entrees
  ReadInputs
}

proc StartStopManager {} {
  global runText continuMode

  if {$runText == "Stop"} {
    set runText Run
    .top.menu.run entryconfigure 0 -state normal
    .top.menu.run entryconfigure 1 -state disabled
  } else {
    if {$continuMode == 1} {
      set runText Stop
      .top.menu.run entryconfigure 0 -state disabled
      .top.menu.run entryconfigure 1 -state normal
      RunContinu
    } else {
      RunDisplay
    }
  }
}

proc RunContinu {} {
  global runText speed

  while {$runText=="Stop"} {
    after $speed(Refresh) {
      RunDisplay
      set continue 1
    }
    vwait continue
    update
    set continue 0
  }
}


# --| RestartSim |------------------------------------------------------------------------
# --  Gestion du redemarage d'une simulation
# ----------------------------------------------------------------------------------------
proc RestartSim {} {
  global runningMode

  # Redemarrage de la simulation
  if {$runningMode == "Simulation"} {
    restart -f
  }
  # aled
  ResetVariables

  # Lecture des entrees
  ReadInputs

  # initialisatin des variables d'entrees
  # initButton  .top.main.inputFrame.switch

  # if {$runningMode == "Target"} {
  #   RunDisplay
  # }
}



# ----------------------------------------------------------------------------------------
# -- Programme principal /////////////////////////////////////////////////////////////////
# ----------------------------------------------------------------------------------------
CheckRunningMode
SetVariables
CreateMainWindow
# if {$runningMode == "Simulation"} {
#   #ConfigWaves
# } else {
#   ConfigBoard
# }
SetOutputs
#ReadInputs

#!/bin/bash

# Creating folders for program
module load mpi/openmpi/4.1.4
PARENT_DIR=$(pwd)"/"
OUTPUT_DIR=$PARENT_DIR"outputs/"
DIR_PARAM_FILES=$PARENT_DIR"parameterfiles/"

GADGET_ROOT=$PARENT_DIR"gadget/"
mkdir -p $OUTPUT_DIR
mkdir -p $PLOT_DIR
mkdir -p $DIR_PARAM_FILES
mkdir -p executables
mkdir -p $OUTPUT_DIR"RECAP/"

# Initial conditions are in: /home/work/HPC_Astro/ICs_exam/
IC_CONDITION_DIR="/home/work/HPC_Astro/ICs_exam/"
GADGET_ROOT=$PARENT_DIR"gadget/"
DIR_EXE=$PARENT_DIR"executables/"
MAIN_MENU_CHECK="1"
SECOND_MENU_CHECK="0"
THIRD_MENU_CHECK="0"


# Create the list of available initial contitions
ls $IC_CONDITION_DIR*.0 | awk -F/ '{print $6}' | awk -F_ '{print $2,$3}' | awk -F. '{print $1}' > $PARENT_DIR"templates/menu.menu"
echo " Back to main menu" >> $PARENT_DIR"templates/menu.menu"
#clear
echo "Welcome to the HPC_EXAM script!"
echo "This script will help you run simulations and view data from finished simulations."

# First while which keeps running the main menu until user exits
while [ $MAIN_MENU_CHECK = "1" ]
do
echo ""
echo " ====================================================================== "
echo " |  HPC_EXAM               EXERCISE 2              Iustin Adrian DINU |"
echo " ======================================================================"
echo ""
echo "                            -----------"
echo "                             MAIN MENU "
echo "                            ----------"
echo " CHOOSE AN OPTION: "
echo " [1] Run a simulation "
echo " [2] View data from finished simulation "
echo " [e] Exit!"
read MENU_CHOICE

if [ "$MENU_CHOICE" = "e" ]; then
   echo "Bye bye! :)"
   exit
fi

if [ "$MENU_CHOICE" = "1" ]; then
    SECOND_MENU_CHECK="1"
    MAIN_MENU_CHECK="0"
    THIRD_MENU_CHECK="0"
fi


# Second while loop which keeps running the [1] Run a simulation menu until user exits
while [ "$SECOND_MENU_CHECK" = "1" ]
do

   # Create a pretty header for second menu
   clear
   echo "                     -------------- "
   echo "                     RUN SIMULATION "
   echo "                     -------------- "
   echo "--------------------------------------------------------------------"
   echo " Which simulation do you want to run [default: e]"
   echo ""

   # Print the aviailable initial conditions
   echo "Available initial conditions:"
   cat -n $PARENT_DIR"templates/menu.menu"
   read MENU_CHOICE_2
   AVAILABLE_SIMULATIONS=$(wc -l $PARENT_DIR"templates/menu.menu" | awk '{print $1}')

   if [ $MENU_CHOICE_2 = $((AVAILABLE_SIMULATIONS)) ]; then
      clear
      MAIN_MENU_CHECK="1"
      SECOND_MENU_CHECK="0"
      THIRD_MENU_CHECK="0"
   fi

   # Check if the user wants to run a simulation
   if [ $MENU_CHOICE_2 -gt 0 ] && [ $MENU_CHOICE_2 -lt $AVAILABLE_SIMULATIONS ]; then
      echo "Running simulation..."
      echo "============================="
      echo " How many task to use? [2-32] "
      read VAR_TASKS
      # Check if the number of tasks is greater than 32 
      if [ $VAR_TASKS -gt 32 ]; then
         echo "Invalid number of tasks! Please try again."
         read -p "Press any key to continue..."
         clear
         SECOND_MENU_CHECK="1"
         MAIN_MENU_CHECK="0"
         THIRD_MENU_CHECK="0"
         GO="0"
      fi
      if [ GO = "0" ]; then
         break
      fi
      # If the number of tasks is greater than 16 then set NODES_USED to 2
      if [ $VAR_TASKS -gt 16 ]; then
         NODES_USED=2
      else
         NODES_USED=1
      fi
      echo "NODES_USED: $NODES_USED"
      # Creating usefuel variables based on the selected simualtion
      SIM_NAME=$(sed -n "$MENU_CHOICE_2"p $PARENT_DIR"templates/menu.menu")         
      VAR_L=$(echo $SIM_NAME | awk '{print $1}')                                 
      VAR_N=$(echo $SIM_NAME | awk '{print $2}')

      # Creating subfolders for the simulation
      mkdir -p $PARENT_DIR"outputs/"$VAR_L"_"$VAR_N"/"$VAR_L"_"$VAR_N"_"$VAR_TASKS
   
      OUTPUT_DIR_TEMP=$PARENT_DIR"outputs/"$VAR_L"_"$VAR_N"/"$VAR_L"_"$VAR_N"_"$VAR_TASKS"/"
      mkdir -p $OUTPUT_DIR_TEMP"data/plots"

      # We need to modify the parameter file for the simulation to include the new initial conditions
      cp $PARENT_DIR"templates/template.param" $DIR_PARAM_FILES$VAR_L"_"$VAR_N"_"$VAR_TASKS".param"
      TEMP_STRING="../ICs_exam/lcdm_LXX_NYY"
      #echo $TEMP_STRING
      TEMP_STRING_2=$IC_CONDITION_DIR"lcdm_"$VAR_L"_"$VAR_N
      #echo $TEMP_STRING_2
      sed -i "s|$TEMP_STRING|$TEMP_STRING_2|g" $DIR_PARAM_FILES$VAR_L"_"$VAR_N"_"$VAR_TASKS".param"
      TEMP_STRING="OUT_CHANGE"
      sed -i "s|$TEMP_STRING|$OUTPUT_DIR_TEMP|g" $DIR_PARAM_FILES$VAR_L"_"$VAR_N"_"$VAR_TASKS".param"
      SOFT_L=$(echo $VAR_L | awk -FL '{print $2}')
      SOFT_N=$(echo $VAR_N | awk -FN '{print $2}')
      VAR_SOFTENING=$(awk -v soft_l="$SOFT_L" -v soft_n="$SOFT_N" 'BEGIN{ printf "%10.2f\n",(1/40)*(soft_l / soft_n)*1000 }')    
      sed -i "s|SOFTENING_CHANGE|$VAR_SOFTENING|g" $DIR_PARAM_FILES$VAR_L"_"$VAR_N"_"$VAR_TASKS".param"
      TEMP_STRING=$(echo $VAR_L  | awk -FL '{printf $2}')
      sed -i "s|LL|$TEMP_STRING|g" $DIR_PARAM_FILES$VAR_L"_"$VAR_N"_"$VAR_TASKS".param"
      OUTPUT_TIME_LIST=$PARENT_DIR"templates/timesteps.template"
      sed -i "s|OUTPUT_TIME_LIST|$OUTPUT_TIME_LIST|g" $DIR_PARAM_FILES$VAR_L"_"$VAR_N"_"$VAR_TASKS".param"
      
      # Creation of the executable for gadget2, we need to copy the Makefile and compile the new executable, with a new name
      cp $PARENT_DIR"templates/Makefile" $GADGET_ROOT"Makefile"
      GADGET_EXE_NAME="gadget2_"$VAR_L"_"$VAR_N"_"$VAR_TASKS

      # Compile the new executable
      cd $GADGET_ROOT
      make clean EXEC=$GADGET_EXE_NAME
      make EXEC=$GADGET_EXE_NAME
      cd $PARENT_DIR
      # Copy the executable to the executables folder
      cp $GADGET_ROOT$GADGET_EXE_NAME $DIR_EXE$GADGET_EXE_NAME


      # Now we need to create the sbatch file to run the simulation
      JOB_NAME=$VAR_L"_"$VAR_N"_"$VAR_TASKS."job"
      mkdir -p $PARENT_DIR"jobs/"
      DIR_SCRIPT=$PARENT_DIR"jobs/"
      cp $PARENT_DIR"templates/job.template" $PARENT_DIR"jobs/"$JOB_NAME
      TEMP_STRING="--ntasks=16"
      TEMP_STRING_2="--ntasks="$VAR_TASKS
      sed -i "s|$TEMP_STRING|$TEMP_STRING_2|g" $DIR_SCRIPT$JOB_NAME
      sed -i "s|--time=02:00:00|--time=10:00:00|g" $DIR_SCRIPT$JOB_NAME
      TEMP_STRING="LXX_NYY_ZZ"
      TEMP_STRING_2=$VAR_L"_"$VAR_N"_"$VAR_TASKS
      sed -i "s|$TEMP_STRING|$TEMP_STRING_2|g" $DIR_SCRIPT$JOB_NAME
      TEMP_STRING="LXX_NYY"
      TEMP_STRING_2=$VAR_L"_"$VAR_N
      sed -i "s|$TEMP_STRING|$TEMP_STRING_2|g" $DIR_SCRIPT$JOB_NAME
      # Set number of nodes to 2
      TEMP_STRING="--nodes=1"
      TEMP_STRING_2="--nodes="$NODES_USED
      sed -i "s|$TEMP_STRING|$TEMP_STRING_2|g" $DIR_SCRIPT$JOB_NAME
      echo "mpirun "$DIR_EXE$GADGET_EXE_NAME $DIR_PARAM_FILES$VAR_L"_"$VAR_N"_"$VAR_TASKS".param" >> $DIR_SCRIPT$JOB_NAME
      
      cd $PARENT_DIR
      sbatch $DIR_SCRIPT$JOB_NAME

      echo "Job sent to SLURM! Simulation started!"
      read -p "Press any key to continue..."
      echo "Simulation finished!"
      SECOND_MENU_CHECK="0"
      MAIN_MENU_CHECK="1"
      THIRD_MENU_CHECK="0"
   fi

done # End of second while loop, so back to main menu

if [ "$MENU_CHOICE" = "2" ]; then
    THIRD_MENU_CHECK="1"
    MAIN_MENU_CHECK="0"
    SECOND_MENU_CHECK="0"

fi


# Third while loop which keeps running the second entry of main menu - [2] View data from finished simulation menu until user exits

while [ $THIRD_MENU_CHECK = "1" ]
do
   # Check if there are finished simulations. To do that we will check if snapshot_5 file exists in the outputs folder
   # We will use the "find" command to search all the subdirectory of the outputs folder for the snapshot_5 file
   # If the file exists, we will print the available simulations and ask the user to choose one to view the data
   # If the file does not exist, we will print a message and go back to the main menu
   if [ $MAIN_MENU_CHECK = "1" ]; then
      clear
   fi
   echo "                     -------------- "
   echo "                        VIEW DATA   "
   echo "                     -------------- "
   echo "--------------------------------------------------------------------"
   echo " Available simulations: "
   echo ""
   cd $PARENT_DIR
   find | grep "snapshot_005"  | awk -F/ {'print $4}' > $PARENT_DIR"templates/complete_sim.menu"
   cat -n $PARENT_DIR"templates/complete_sim.menu"
   NUMBER_OF_SIMULATIONS=$(wc -l $PARENT_DIR"templates/complete_sim.menu" | awk '{print $1}')

   # Now we do the analysis for each individual simulation. We will retrive some basic information like
   # simName, L, N, taskUsed, step, simTime, cpuTime, workloadBalance, particlepersec
   # We will print this information in a table format

   # First create a copy of $PARENT_DIR"templates/recapSingleSim.template" and add the header to it
   # for each available simulation. 
   DIR_RECAP=$PARENT_DIR"outputs/RECAP/"
   cp $PARENT_DIR"templates/recapAll.template" $PARENT_DIR"outputs/RECAP/GENERAL_RECAP.dat"
   echo " " >> $PARENT_DIR"outputs/RECAP/GENERAL_RECAP.dat"
   for i in $(seq 1 $NUMBER_OF_SIMULATIONS)
   do
      
      SIM_NAME_TEMP=$(sed -n "$i"p $PARENT_DIR"templates/complete_sim.menu")
      
      tail -n 1 $PARENT_DIR"templates/recapSingleSim.template" > $PARENT_DIR"outputs/RECAP/recap_"$SIM_NAME_TEMP".dat"
      echo " " >> $PARENT_DIR"outputs/RECAP/recap_"$SIM_NAME_TEMP".dat"

      # Then we will add the information for each simulation
      VAR_L_TEMP=$(echo $SIM_NAME_TEMP | awk -F_ '{print $1}')
      VAR_N_TEMP=$(echo $SIM_NAME_TEMP | awk -F_ '{print $2}')
      VAR_TASK_TEMP=$(echo $SIM_NAME_TEMP | awk -F_ '{print $3}')
      DIR_OUTPUT_SIM_TEMP=$PARENT_DIR"outputs/"$VAR_L_TEMP"_"$VAR_N_TEMP"/"$VAR_L_TEMP"_"$VAR_N_TEMP"_"$VAR_TASK_TEMP"/"

      # For reducing the number of data, we will delete the restart.* files to save space. Just from the simulations that are finished
      cd $DIR_OUTPUT_SIM_TEMP
      #rm -f restart.*
      cd $PARENT_DIR

      # Here we extrac data from logfiles of each simulation we will use a garbage directory to store the intermediate files
      mkdir -p $DIR_RECAP"garbage/$SIM_NAME_TEMP"
      DIR_GARBAGE_SIM_TEMP=$DIR_RECAP"garbage/"$SIM_NAME_TEMP"/"
      cd $DIR_OUTPUT_SIM_TEMP
      cat timings.txt | grep "Step" | awk '{print $2}' > $DIR_GARBAGE_SIM_TEMP"step.dat"
      cat timings.txt | grep "Step" | awk '{print $4}' > $DIR_GARBAGE_SIM_TEMP"simTime.dat"
      cat timings.txt | grep "Step" | awk '{print $6}' > $DIR_GARBAGE_SIM_TEMP"dt.dat"
      cat timings.txt | grep "work-load" | awk '{print $3}' > $DIR_GARBAGE_SIM_TEMP"workload.dat"
      cat timings.txt | grep "particle-load" | awk '{print $3}' > $DIR_GARBAGE_SIM_TEMP"particleLoad.dat"
      cat timings.txt | grep "part/sec" | awk '{print $3}' > $DIR_GARBAGE_SIM_TEMP"partPerSec.dat"
      cat timings.txt | grep "Nf=" | awk '{print $2}' > $DIR_GARBAGE_SIM_TEMP"Nf.dat"
      

      # Now we gets cpus times 
      # first grep the lines with "Step" and the next line after that, then grep the lines with "Step" and remove them, resulting
      # in a file with only the cpu times
      cat cpu.txt | grep -A 1 "Step" | grep -v "Step" > $DIR_GARBAGE_SIM_TEMP"cpu_temp.dat"
      # Then we will extract only the first column of the file, which contains the cpu wallclock time
      cat $DIR_GARBAGE_SIM_TEMP"cpu_temp.dat" | awk '{print $1}' > $DIR_GARBAGE_SIM_TEMP"cpu.dat"
      echo $(tail -n 1 $DIR_GARBAGE_SIM_TEMP"cpu.dat") >> $DIR_GARBAGE_SIM_TEMP"cpu.dat"
      # Now we will paste the cpu times to the recap file
      paste $DIR_GARBAGE_SIM_TEMP"step.dat" $DIR_GARBAGE_SIM_TEMP"simTime.dat" $DIR_GARBAGE_SIM_TEMP"dt.dat" $DIR_GARBAGE_SIM_TEMP"workload.dat" $DIR_GARBAGE_SIM_TEMP"particleLoad.dat" $DIR_GARBAGE_SIM_TEMP"partPerSec.dat" $DIR_GARBAGE_SIM_TEMP"cpu.dat" $DIR_GARBAGE_SIM_TEMP"Nf.dat" >> $DIR_RECAP"recap_"$SIM_NAME_TEMP".dat"

      # Now we need to generate data for the GENERAL RECAP file for all simulations
      
      AVG_WORKLOAD=$(awk '{ sum += $4; n++ } END { if (n > 0) print sum / n; }' $DIR_RECAP"recap_"$SIM_NAME_TEMP".dat")
      AVG_PARTICLE_LOAD=$(awk '{ sum += $5; n++ } END { if (n > 0) print sum / n; }' $DIR_RECAP"recap_"$SIM_NAME_TEMP".dat")
      AVG_PART_PER_SEC=$(awk '{ sum += $6; n++ } END { if (n > 0) print sum / n; }' $DIR_RECAP"recap_"$SIM_NAME_TEMP".dat")
      # Wallclock time is the last value in the cpu.dat file times the number of tasks
      WALL_CPU_TIME=$(tail -n 1 $DIR_GARBAGE_SIM_TEMP"cpu.dat")
      WALL_CPU_TIME=$(echo $WALL_CPU_TIME | awk '{print $1}')
      
      # Now we will add the information for each simulation to the GENERAL_RECAP file
      echo $SIM_NAME_TEMP $VAR_L_TEMP $VAR_N_TEMP $VAR_TASK_TEMP $WALL_CPU_TIME  $AVG_WORKLOAD $AVG_PARTICLE_LOAD $AVG_PART_PER_SEC >> $PARENT_DIR"outputs/RECAP/GENERAL_RECAP.dat"

      
      

   done
   # Sort the GENERAL_RECAP file first by L, then by N, then by number of tasks
   sort -t' ' -k2,2 -k3,3 -k4,4n $PARENT_DIR"outputs/RECAP/GENERAL_RECAP.dat"> $PARENT_DIR"outputs/RECAP/GENERAL_RECAP_SORTED.dat"
   mv $PARENT_DIR"outputs/RECAP/GENERAL_RECAP_SORTED.dat" $PARENT_DIR"outputs/RECAP/GENERAL_RECAP.dat"
   

   # If there are no finished simulations, we will print a message and go back to the main menu
   if [ $NUMBER_OF_SIMULATIONS -eq 0 ]; then
      echo "No finished simulations found!"
      read -p "Press [ENTER] to continue..."
      THIRD_MENU_CHECK="0"
      MAIN_MENU_CHECK="1"
   fi

   echo " ------------------------------------------------------------------- "
   echo " "
   echo " Which simulations do you want to view? [1, 2, 3, ..., n]"
   echo " If you want a recap for all simulations, in tabular form, press [a]"
   echo " If you want to exit, press [e]"
   read MENU_CHOICE_3

   # If user wants to exit, go back to the main menu
   if [ "$MENU_CHOICE_3" = "e" ]; then
      THIRD_MENU_CHECK="0"
      MAIN_MENU_CHECK="1"
      SECOND_MENU_CHECK="0"
   fi
   
   if [ "$MENU_CHOICE_3" = "a" ]; then
         THIRD_MENU_CHECK="1"
         MAIN_MENU_CHECK="0"
         SECOND_MENU_CHECK="0"
         
         echo " --------------- RECAP OF ALL SIMULATIONS ------------------"
         echo " "
         column -t $PARENT_DIR"outputs/RECAP/GENERAL_RECAP.dat"
         echo " "
         echo " -----------------------------------------------------------"
         echo " "
   fi

   # If user choose one valid simulation, so MENU_CHOICE should be less than number of available simulation
   # then we will print the data for that simulation, otherwise we will print an error message
   if [ "$MENU_CHOICE_3" != "e" ]; then
      
      if [[ $MENU_CHOICE_3 -gt $NUMBER_OF_SIMULATIONS ]] || [[ $MENU_CHOICE_3 -eq 0 ]]; then
         echo "Invalid choice! Please try again." 
         read -p "Press [ENTER] to continue..."
         clear
         THIRD_MENU_CHECK="1"
         MAIN_MENU_CHECK="0"
         SECOND_MENU_CHECK="0"
      elif [ "$MENU_CHOICE_3" -lt $(($NUMBER_OF_SIMULATIONS+1)) ]; then
         echo "Viewing simulation..."
         # View the simulation

         # Get the name of the simulation
         SIM_NAME_TEMP=$(sed -n "$MENU_CHOICE_3"p $PARENT_DIR"templates/complete_sim.menu") #| awk -F/ '{print $4}')
         DIR_GARBAGE_SIM_TEMP=$DIR_RECAP"garbage/"$SIM_NAME_TEMP"/"
         VAR_L_TEMP=$(echo $SIM_NAME_TEMP | awk -F_ '{print $1}')
         VAR_N_TEMP=$(echo $SIM_NAME_TEMP | awk -F_ '{print $2}')
         VAR_TASK_TEMP=$(echo $SIM_NAME_TEMP | awk -F_ '{print $3}')
         AVG_WORKLOAD=$(awk '{ sum += $4; n++ } END { if (n > 0) print sum / n; }' $DIR_RECAP"recap_"$SIM_NAME_TEMP".dat")
         AVG_PARTICLE_LOAD=$(awk '{ sum += $5; n++ } END { if (n > 0) print sum / n; }' $DIR_RECAP"recap_"$SIM_NAME_TEMP".dat")
         AVG_PART_PER_SEC=$(awk '{ sum += $6; n++ } END { if (n > 0) print sum / n; }' $DIR_RECAP"recap_"$SIM_NAME_TEMP".dat")
         # Wallclock time is the last value in the cpu.dat file times the number of tasks
         WALL_CPU_TIME=$(tail -n 1 $DIR_GARBAGE_SIM_TEMP"cpu.dat")
         WALL_CPU_TIME=$(echo $WALL_CPU_TIME | awk '{print $1}')

         echo " ---------------- $SIM_NAME_TEMP --------------- "
         echo ""
         echo "VAR_L_TEMP: $VAR_L_TEMP"
         echo "VAR_N_TEMP: $VAR_N_TEMP"
         echo "VAR_TASK_TEMP: $VAR_TASK_TEMP"
         echo "AVG_WORKLOAD: $AVG_WORKLOAD"
         echo "AVG_PARTICLE_LOAD: $AVG_PARTICLE_LOAD"
         echo "AVG_PART_PER_SEC: $AVG_PART_PER_SEC"
         echo "WALL_CPU_TIME: $WALL_CPU_TIME"
         echo ""
         
         
         head -n5 $DIR_RECAP"recap_"$SIM_NAME_TEMP".dat" | column -t
         echo " "
         echo " ... some data ... "
         echo "  "
         tail -n5 $DIR_RECAP"recap_"$SIM_NAME_TEMP".dat" | column -t
         

         #head -n 10 $PARENT_DIR"outputs/"$VAR_L_TEMP"_"$VAR_N_TEMP"/"$VAR_L_TEMP"_"$VAR_N_TEMP"_"$VAR_TASK_TEMP"/parameters-usedvalues"
         echo " "
         echo " Press any key to continue..."
         read test
         THIRD_MENU_CHECK="1"
         MAIN_MENU_CHECK="0"
         SECOND_MENU_CHECK="0"
         # If user wants to exit, go back to the main menu
      fi
   fi

done # end of the third while loop, so back to main menu

done # End of first while loop, so end of the 



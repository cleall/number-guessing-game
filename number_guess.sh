#!/bin/bash

# read variables below from .env file
if [ -f .env ]; then
  export $(cat .env | xargs)
fi

# define PSQL variable to query db
PSQL="psql -X --username=$USERNAME --dbname=$DB_NAME --tuples-only -c"

# get random number 1-1000
NUMBER=$((1 + $RANDOM % 1000))

# set number of guesses counter to 0
COUNT=0

WELCOME() {
  # prompt user for name
  echo "Enter your username:"
  read USERNAME

  # check name length ?
  if [[ ! $USERNAME =~ ^([a-zA-Z0-9_]){1,22}$ ]]
  then
    echo Username is too long.
  else
    #get user name from db
    USER_ID=$($PSQL "SELECT id_user FROM users WHERE name='$USERNAME'")
    # if user exists
    if [[ $USER_ID ]]
    then
      # get user data
      GAMES_PLAYED=$($PSQL "SELECT COUNT(id_user) FROM game WHERE id_user=$USER_ID")
      BEST_GAME=$($PSQL "SELECT MIN(best_game) FROM game WHERE id_user=$USER_ID")
      # format variables removing spaces
      GAMES_PLAYED_FMT=$(echo $GAMES_PLAYED | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')
      BEST_GAME_FMT=$(echo $BEST_GAME | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')
      # greet user
      echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED_FMT games, and your best game took $BEST_GAME_FMT guesses."
    else
      # if user does not exist
      echo -e "\nWelcome, $USERNAME It looks like this is your first time here."
      # register user
      INSERT_USER_RESULT=$($PSQL "INSERT INTO users(name) VALUES('$USERNAME')")
      # if username is not created
      if [[ $INSERT_USER_RESULT != "INSERT 0 1" ]]
      then
        echo -e "\nCould not register new user. Please try again."
      else
        # retrieve new user id
        USER_ID=$($PSQL "SELECT id_user FROM users WHERE name='$USERNAME'")
      fi
    fi
    # start playing
    PLAY
  fi
}

PLAY(){
  # get guess number from user
  echo -e "\nGuess the secret number between 1 and 1000:"
  read GUESS

  # if guess is not a number
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    ((COUNT++))
    echo -e "\nThat is not an integer, guess again:"    
    PLAY
  # if guess is less than secret number
  elif [[ $GUESS -gt $NUMBER ]]
  then
    ((COUNT++))
    echo -e "\nIt's lower than that, guess again:"      
    PLAY
  # if guess is higher than secret number
  elif [[ $GUESS -lt $NUMBER ]]
  then
    ((COUNT++))
    echo -e "\nIt's higher than that, guess again:"
    PLAY
  # if guess is correct
  elif [[ $GUESS -eq $NUMBER ]]
  then
    ((COUNT++))
    echo -e "\nYou guessed it in $COUNT tries. The secret number was $NUMBER. Nice job!"
    # save user game data
    INSERT_GAME_DATA_RESULT=$($PSQL "INSERT INTO game(id_user, best_game) VALUES($USER_ID,$COUNT)")
  fi
}

WELCOME
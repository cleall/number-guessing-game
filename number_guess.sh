#!/bin/bash

# read variables below from .env file
if [ -f .env ]; then
  export $(cat .env | xargs)
fi

# define PSQL variable to query db
PSQL="psql -X --username=$DB_USERNAME --dbname=$DB_NAME -t --no-align -c"

WELCOME() {
  # prompt user for name
  echo -e "\nEnter your username:"
  read USERNAME

  # get random number 1-1000
  NUMBER=$((1 + $RANDOM % 1000))

  # set number of guesses counter to 0
  GUESS_COUNTER=0

  #If that username has been used before, it should print
  USER=$($PSQL "SELECT name FROM users WHERE name='$USERNAME'")
  if [[ ! -z $USER ]]
  then
    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
    INSERT_USER=$($PSQL "INSERT INTO users(name, best_game, games_played) VALUES('$USERNAME',NULL,NULL)")
  else
    # get user data
    USER_ID=$($PSQL "SELECT id_user FROM users WHERE name='$USERNAME'")
    USER_NAME_DB=$($PSQL "SELECT name FROM users WHERE name='$USERNAME'")
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE id_user=$USER_ID")
    BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE id_user=$USER_ID")
    echo -e "\nWelcome back, $USER_NAME_DB! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi
  PLAY
}

PLAY(){
  # flag to end game
  END=0
  # get guess number from user
  echo -e "\nGuess the secret number between 1 and 1000:"
  
  # Use a while loop instead of calling PLAY function again
  while [[ $END -eq 0 ]]
  do
    # get guess from user
    read GUESS
    # if guess is not a number
    if [[ ! $GUESS =~ ^[0-9]+$ ]]
    then
      ((GUESS_COUNTER++))
      echo -e "\nThat is not an integer, guess again:"
    # if guess is correct
    elif [[ $GUESS -eq $NUMBER ]]
    then
      ((GUESS_COUNTER++))
      echo -e "\nYou guessed it in $GUESS_COUNTER tries. The secret number was $NUMBER. Nice job!"
      # save user game data
      ((GAMES_PLAYED++))
      SET_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE name='$USERNAME'")
      SET_BEST_GAME=$($PSQL "UPDATE users SET best_game=$GUESS_COUNTER WHERE name='$USERNAME' AND (best_game ISNULL OR $GUESS_COUNTER < best_game)")
      END=1
    # if guess is less than secret number
    elif [[ $GUESS -gt $NUMBER ]]
    then
      ((GUESS_COUNTER++))
      echo -e "\nIt's lower than that, guess again:"      
      PLAY
    # if guess is higher than secret number
    elif [[ $GUESS -lt $NUMBER ]]
    then
      ((GUESS_COUNTER++))
      echo -e "\nIt's higher than that, guess again:"
      PLAY    
    fi
  done
}

WELCOME

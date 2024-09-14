#!/bin/bash

# Command to execute SQL queries
PSQL="psql --username=freecodecamp --dbname=salon --no-align --tuples-only -c"

# Command to export the database to salon.sql
EXPORT_DB="pg_dump -cC --inserts -U freecodecamp salon > salon.sql"

# Function to display the list of services
DISPLAY_SERVICES() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # Get and display the list of services
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  echo -e "\nHere are the services we offer:"
  echo "$SERVICES" | while IFS="|" read SERVICE_ID SERVICE_NAME
  do
    # Formatted output like 1) Haircut
    echo "$SERVICE_ID) $SERVICE_NAME"
  done
}

# Display the list of services at the beginning
DISPLAY_SERVICES

# Ask the user to select a service
read SERVICE_ID_SELECTED

# Verify if the service ID is valid
SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")

# If the service ID is invalid, prompt the user to select again
while [[ -z $SERVICE_NAME ]]
do
  DISPLAY_SERVICES "This service does not exist. Please choose a valid service."
  read SERVICE_ID_SELECTED
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
done

# Ask for the customer's phone number
echo -e "\nPlease enter your phone number:"
read CUSTOMER_PHONE

# Check if the customer already exists
CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

# If the customer doesn't exist, ask for their name and add them to the customers table
if [[ -z $CUSTOMER_NAME ]]
then
  echo -e "\nI couldn't find you in our database. What is your name?"
  read CUSTOMER_NAME
  INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
fi

# Retrieve the customer's ID
CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

# Ask for the appointment time
echo -e "\nAt what time would you like to schedule the appointment?"
read SERVICE_TIME

# Insert the appointment into the appointments table
INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

# Confirm the appointment for the customer
echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."

# Execute the database export
echo -e "\nExporting the database..."
$EXPORT_DB
echo -e "Export complete! The 'salon.sql' file has been created."

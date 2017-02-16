#!/usr/bin/env python
# -*- coding: utf-8 -*-
import smtplib, sys


def send_email(user, pwd, recipient, subject, body):
    """
    Basic Email Set up for sending a notification
        :param user: The User Name for the account
        :param pwd: The password for the account
        :param recipient: Who to send the Email to
        :param subject: The Subject of the Email
        :param body: The Body of the email
        :return: None
    """
    gmail_user = user
    gmail_pwd = pwd
    FROM = user
    TO = recipient if type(recipient) is list else [recipient]
    SUBJECT = subject
    TEXT = body

    # Prepare actual message
    message = """From: %s\nTo: %s\nSubject: %s\n\n%s
    """ % (FROM, ", ".join(TO), SUBJECT, TEXT)
    try:
        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.ehlo()
        server.starttls()
        server.login(gmail_user, gmail_pwd)
        server.sendmail(FROM, TO, message)
        server.close()
        print('successfully sent the mail')
    except:
        print("failed to send mail")


if __name__ == '__main__':
    # Get the Array of Arguments from stdin
    args = sys.argv[1:]

    # Parse the Array for the subject and the message
    subject = args[0]
    message = args[1]

    # The stdin for the subject is passed with _ and is replaced with a space
    subject = subject.replace('_', ' ')
    # A New line is passed in with and ### and replaced with the newline
    message = message.replace("###", "\n")
    message = message.replace('_', ' ')
    # Send the Email
    send_email('ITbot@personalgenome.com', 'Persona!', 'astangl@personalgenome.com', subject, message)

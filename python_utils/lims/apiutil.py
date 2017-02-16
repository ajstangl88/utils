#!/usr/local/bin/env python
import requests
import xml.etree.ElementTree as et
DEBUG = 0


class apiutil:

    def __init__(self):
        """
        Instantiation of hostname, authentication, and api version
        :return: None
        """
        if DEBUG > 0: print(self.__module__ + ' init Called')
        self.hostname = ''
        self.auth_handler = ''
        self.version = ''

    def setHostname(self, hostname):
        """
        Set host of webservice
        :param hostname: String for hostname
        :return: None
        """
        if DEBUG > 0: print(self.__module__ + ' setHostname Called')
        self.hostname = hostname
        return hostname

    def setVersion(self, version):
        """
        Set API version used
        :param version: string for API version
        :return: None
        """
        self.version = version
        return version

    def authHandler(self, user, password):
        """
        Sets authentication for target webservice
        :param user: string of username
        :param password: string of password
        :return: tuple of (user, name) for request authentication
        """
        if DEBUG > 0: print(self.__module__ + ' authHandler Called')
        self.user = user
        self.password = password
        self.auth_handler = (user, password)
        return self.auth_handler

    def getRequest(self, url):
        if DEBUG > 0: print(self.__module__ + ' getRequest Called')
        self.url = url
        r = requests.get(url, auth=self.auth_handler)
        return r.content

    def postRequest(self, url, data):
        headers = {'Accept': 'application/xml', 'Content-Type': 'application/xml', 'User-Agent': 'Python-requests'}
        if DEBUG > 0: print(self.__module__ + ' postRequest Called')
        self.url = url
        r = requests.post(url, headers=headers, data=data, auth=self.auth_handler)
        return r.content

    def putRequest(self, url, data):
        headers = {'Accept': 'application/xml', 'Content-Type': 'application/xml', 'User-Agent': 'Python-requests'}
        if DEBUG > 0: print(self.__module__ + ' postRequest Called')
        self.url = url
        r = requests.put(url, headers=headers, data=data, auth=self.auth_handler)
        return r.content


    def mapIO(self, tree):
        dat = [{item.tag: item.attrib for item in ch} for ch in tree.findall('input-output-map')]
        return dat


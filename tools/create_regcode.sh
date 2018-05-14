#!/bin/bash

uuidgen -r | sed s/-//g | sed -r 's/(\w{4})(\w{4})(\w{4})(\w{4})(\w{4}).*/\1-\2-\3-\4-\5/' | tr '[:lower:]' '[:upper:]'



#!/bin/env python3
# The format of a todo file is extremely simple
# =======
# Example
# =======
# Task1
# - Subtask1
# - Subtask2~
# Task2
# - Subtask3
#
# Here, Subtask2 is a completed subtask
# NOTE: We always maintain the line number invariant.

import argparse
import sys
import re


class TodoItem:
    def set_task(self, task):
        self.task = task

    def set_depth(self, depth):
        self.depth = depth

    def set_complete(self, completed):
        self.completed = completed


class TodoList:
    def __init__(self, todo_filename):
        self.backing_file = todo_filename
        self.todo_list = []
        with open(todo_filename) as inp:
            for line in inp:
                depth = len((re.findall(r'^-*', line))[0])
                line = line.replace('-', '').strip()
                completed = line[-1] == '~'
                line = line.replace('~', '').strip()

                item = TodoItem()
                item.set_depth(depth)
                item.set_task(line)
                item.set_complete(completed)
                self.todo_list.append(item)

    def write_file(self):
        with open(self.backing_file, 'w') as ofile:
            for item in self.todo_list:
                line = ''
                line += '-'*item.depth + ' '
                line += item.task
                if item.completed:
                    line += ' ~'
                print(line, file=ofile)

    def print_pending(self):
        for idx, item in enumerate(self.todo_list):
            if item.completed:
                continue
            line = '\t'*item.depth + ' '
            line += item.task
            print(idx, line)

    def add_task(self, position, task_str, depth=0):
        newtask = TodoItem()
        newtask.set_complete(False)
        newtask.set_depth(depth)
        newtask.set_task(task_str)
        self.todo_list.insert(position, newtask)

    def process_command(self, cmd_string) -> bool:
        def process_add(args):
            prev_loc = int(args[0])
            task = ' '.join(args[1:])
            self.add_task(prev_loc+1, task)

        def process_addsub(args):
            prev_loc = int(args[0])
            task = ' '.join(args[1:])
            prev_depth = self.todo_list[prev_loc].depth
            self.add_task(prev_loc+1, task, prev_depth+1)

        def process_done(args):
            task_loc = int(args[0])
            self.todo_list[task_loc].set_complete(True)

        def process_print(_):
            self.print_pending()

        COMMANDS = {"add": process_add,
                    "addsub": process_addsub, "done": process_done,
                    "print": process_print}

        cmd_args = cmd_string.split()
        cmd = cmd_args[0]
        args = cmd_args[1:]

        if cmd not in COMMANDS:
            return False

        try:
            COMMANDS[cmd](args)
            return True
        except (IndexError, ValueError) as e:
            print(f"Error occured: {e}", file=sys.stderr)
            return False


def main():
    arg_parser = argparse.ArgumentParser(
        description="A tool for interacting with todo files")

    arg_parser.add_argument("todo_file", type=str, help="Input todo file")
    args = arg_parser.parse_args()

    todolist = TodoList(args.todo_file)

    try:
        while (True):
            cmd = input()
            ret = todolist.process_command(cmd)
            if ret == False:
                print(
                    f"Error occured while processing '{cmd}'", file=sys.stderr)
                break
    except EOFError:
        todolist.write_file()


if __name__ == '__main__':
    main()

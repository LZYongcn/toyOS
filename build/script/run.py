import iterm2
import AppKit
import os

os.system("open -a /Applications/iTerm.app/")


async def main(connection):
    app = await iterm2.async_get_app(connection=connection, create_if_needed=True)
    await app.async_activate()
    await app.current_window.current_tab.current_session.async_send_text("bash -ic 'cdbox;bochs -q'\n")

iterm2.run_until_complete(main)
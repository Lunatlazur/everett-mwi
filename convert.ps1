$asm = ("System.Windows.Forms")
$src = @"
using System;
using System.Windows.Forms;

public class RPGMVEventCommandContext {
   public static void Convert() {
      string data = null;
      text = Clipboard.GetText();
      data = System.Text.Encoding.UTF8.GetBytes(data);
      System.IO.MemoryStream ms = new System.IO.MemoryStream(data);
      Clipboard.SetData("application/rpgmz-EventCommand", ms);
   }
}
"@
Add-Type -TypeDefinition $src -Language CSharp -ReferencedAssemblies $asm
[RPGMVEventCommandContext]::Convert()

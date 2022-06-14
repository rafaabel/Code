$cred = get-credential
$session = new-pssession -authentication basic -credential $cred -connectionuri https://mail.o365.effem.com/powershell -configuration microsoft.exchange -SessionOption (New-PSSessionOption -SkipRevocationCheck)
import-pssession $session 
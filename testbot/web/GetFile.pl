# -*- Mode: Perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# Returns the specified Step/Task file.
#
# Copyright 2009 Ge van Geldorp
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA

use strict;

use Apache2::Const -compile => qw(REDIRECT);
use CGI;
use Fcntl; # For O_XXX
use WineTestBot::Config;
use WineTestBot::Jobs;
use WineTestBot::Steps;

sub GetFile($$$$)
{
  my ($Request, $JobKey, $StepKey, $TaskKey) = @_;

  # Validate and untaint
  if (! ($JobKey =~ m/^(\d+)$/))
  {
    return !1;
  }
  $JobKey = $1;
  if (! ($StepKey =~ m/^(\d+)$/))
  {
    return !1;
  }
  $StepKey = $1;
  if (! defined($TaskKey))
  {
    $TaskKey = undef;
  }
  elsif ($TaskKey =~ m/^(\d+)$/)
  {
    $TaskKey = $1;
  }
  else
  {
    return !1;
  }

  my $Job = CreateJobs()->GetItem($JobKey);
  if (! defined($Job))
  {
    return !1;
  }
  my $Step = $Job->Steps->GetItem($StepKey);
  if (! defined($Step))
  {
    return !1;
  }

  my $FileName = "$DataDir/jobs/$JobKey/$StepKey/" . 
                 (defined($TaskKey) ? "$TaskKey/TestFiles.zip" :
                  $Step->FileName);
  if (! sysopen(FILE, $FileName, O_RDONLY))
  {
    return !1;
  }
  my $BlkSize = (stat FILE)[11] || 16384;
  my $ImageBytes;
  my $ImageSize = 0;
  my $Len;
  while ($Len = sysread(FILE, $ImageBytes, $BlkSize, $ImageSize))
  {
    if (! defined($Len))
    {
      close FILE;
      return !1;
    }
    $ImageSize += $Len;
  }
  close FILE;
 
  # Date in the past
  $Request->headers_out->add("Expires", "Sun, 25 Jul 1997 05:00:00 GMT");
  
  # always modified
  $Request->headers_out->add("Last-Modified", (scalar gmtime) . " GMT");
  
  # HTTP/1.1
  $Request->headers_out->add("Cache-Control", "no-cache, must-revalidate, " .
                                              "post-check=0, pre-check=0");
  
  # HTTP/1.0
  $Request->headers_out->add("Pragma", "no-cache");
  
  if (defined($TaskKey))
  {
    # Zip file
    $Request->content_type("application/zip");
    $Request->headers_out->add("Content-Disposition",
                               'attachment; filename="TestFiles.zip"');
  }
  else
  {
    # Binary file
    $Request->content_type("application/octet-stream");
    $Request->headers_out->add("Content-Disposition",
                               'attachment; filename="' . $Step->FileName .
                               '"');
  }

  print $ImageBytes;

  return 1;
}

my $Request = shift;

my $CGIObj = CGI->new($Request);
my $JobKey = $CGIObj->param("JobKey");
my $StepKey = $CGIObj->param("StepKey");
my $TaskKey = $CGIObj->param("TaskKey");
if (! GetFile($Request, $JobKey, $StepKey, $TaskKey))
{
  $Request->headers_out->set("Location", "/");
  $Request->status(Apache2::Const::REDIRECT);
}

exit;

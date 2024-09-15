if(NOT "/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/CMakeTests" MATCHES "^/")
  set(slash /)
endif()
set(url "file://${slash}/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/CMakeTests/FileDownloadInput.png")
set(dir "/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/CMakeTests/downloads")

file(DOWNLOAD
  ${url}
  ${dir}/file3.png
  TIMEOUT 2
  STATUS status
  EXPECTED_HASH SHA1=5555555555555555555555555555555555555555
  )

<a name="readme-top"></a>

<!-- Projet Shields -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- Replace these markers with infos - "VSS-Monitoring"-->


<div align="center">


<h3 align="center">VSS Monitoring</h3>
  <p align="center">
    <a href="https://github.com/Isnubi/VSS-Monitoring/"><strong>Explore the docs »</strong></a>
    <br />--------------------
    <br />
    <a href="https://github.com/Isnubi/VSS-Monitoring/issues">Report Bug</a>
    ·
    <a href="https://github.com/Isnubi/VSS-Monitoring/issues">Request Feature</a>
  </p>
</div>


<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

This project is a monitoring tool for the [VSS service](https://learn.microsoft.com/en-us/windows-server/storage/file-server/volume-shadow-copy-service).

The first script enables you to monitor the disk space used by the VSS service. You can specify a threshold to see if the disk space used by the VSS service is above or below the threshold.

*Thanks to Kelvin Tegelaar who created the initial version I used as a base for this project: https://www.cyberdrain.com/monitoring-with-powershell-vss-snapshot-size/*<br>


The second script enables you to check if the VSS service is enable on a server. If it is not, it will send an email to prevent you from having a problem with the VSS service.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

* [![Powershell][powershell-shield]][powershell-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

To use this script, you need to:
* Download the script
* Set your threshold in the script
* Run the script:
    * You may authorize the script to run by running the following command in an elevated PowerShell prompt:
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
    ```
    * Run it in an elevated PowerShell prompt:
    ```powershell
    .\VSS-Threshold.ps1
    .\is_VSS_Enable.ps1
    ```


<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap


See the [open issues](https://github.com/Isnubi/VSS-Monitoring/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.md` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact


Isnubi - [@Louis_Gambart](https://twitter.com/Louis_Gambart) - [contact@louis-gambart.fr](mailto:louis-gambart.fr)
<br>**Discord:** isnubi#6221

**Project Link:** [https://github.com/Isnubi/VSS-Monitoring](https://github.com/Isnubi/VSS-Monitoring)

<p align="right">(<a href="#readme-top">back to top</a>)</p>




<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/Isnubi/VSS-Monitoring.svg?style=for-the-badge
[contributors-url]: https://github.com/Isnubi/VSS-Monitoring/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/Isnubi/VSS-Monitoring.svg?style=for-the-badge
[forks-url]: https://github.com/Isnubi/VSS-Monitoring/network/members
[stars-shield]: https://img.shields.io/github/stars/Isnubi/VSS-Monitoring.svg?style=for-the-badge
[stars-url]: https://github.com/Isnubi/VSS-Monitoring/stargazers
[issues-shield]: https://img.shields.io/github/issues/Isnubi/VSS-Monitoring.svg?style=for-the-badge
[issues-url]: https://github.com/Isnubi/VSS-Monitoring/issues
[license-shield]: https://img.shields.io/github/license/Isnubi/VSS-Monitoring.svg?style=for-the-badge
[license-url]: https://github.com/Isnubi/VSS-Monitoring/blob/master/LICENSE.md
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/louis-gambart
[Powershell-shield]: https://img.shields.io/badge/-Powershell-5391FE?style=for-the-badge&logo=powershell&logoColor=white
[Powershell-url]: https://docs.microsoft.com/en-us/powershell/
[Twitter-shield]: https://img.shields.io/twitter/follow/Louis_Gambart?style=social
[Twitter-url]: https://twitter.com/Louis_Gambart/
